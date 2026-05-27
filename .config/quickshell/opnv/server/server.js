require('dotenv').config();
const mariadb = require('mariadb');
const express = require('express');
const GtfsRealtimeBindings = require('gtfs-realtime-bindings')

const app = express();

app.use(express.json());

const EXPRESS_PORT = 3050;

const ERROR = {
    MISSING_CREDENTIALS: 100,
    INVALID_CREDENTIALS: 101,
    INVALID_AUTH_HEADER: 102,
    INVALID_CLIENT_TOKEN: 103,
    NO_LOGIN: 104,
    INVALID_SESSION: 105,
    CAPTCHA_MISSING: 106,
    INVALID_CAPTCHA: 107,
    EMAIL_OCCUPIED: 108,
    NOT_EMAIL: 109,
    INVALID_EMAIL_CODE: 110,
    CHEATED: 111,
    INTERNAL_ERROR: 112,
    INVALID_REDIRECT_URI: 113,
    MISSING_QUERY: 114,
    MISSING_DATA: 115,
    DATA_NOT_FOUND: 116,
    SIGNUP_SUCCESS: 0
}


const FEEDS = {
    de: "https://realtime.gtfs.de/realtime-free.pb"
}

const dbPool = mariadb.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER,
    password: process.env.DB_PASS,
    database: process.env.DB_NAME,
    connectionLimit: 5
});

app.get("/stops/search", async (req, res) => {
    const query = req.query.q;
    const offset = req.query.offset;

    if (!query)
        return res.status(400).json({ success: false, error: ERROR.MISSING_QUERY, message: "No query provided!" });

    let conn;
    try {
        conn = await dbPool.getConnection();

        const likePattern = `%${query.split(' ').join('%')}%`;

        const rows = await conn.query(
            `SELECT stop_name,
                    JSON_ARRAYAGG(stop_id) AS stop_ids,
                    JSON_ARRAYAGG(parent_station) AS parent_stations,
                    AVG(stop_lat) AS lat,
                    AVG(stop_lon) AS lon
             FROM stops
             WHERE stop_name LIKE ?
             GROUP BY stop_name
             LIMIT ? OFFSET ?`,
            [`%${likePattern}%`, 20, parseInt(offset)]
        );

        return res.status(200).json({ success: true, result: rows });
    } catch (e) {
        console.log(e);
        return res.status(500).json({ success: false, error: ERROR.INTERNAL_ERROR, message: "Internal Server Error" })
    } finally {
        conn.release();
    }
});

app.get("/stops/:stop_id/name", async (req, res) => {
    const stop_id = req.params.stop_id;

    if (!stop_id) return res.status(400).json({ success: false, error: ERROR.MISSING_DATA, message: "stop_id is not provided"});

    let conn;
    try {
        conn = await dbPool.getConnection();

        const rows = await conn.query(`SELECT * FROM stops WHERE stop_id=?`, [stop_id]);

        if (rows.length <= 0) return (res.status(404).json({ success: false, error: ERROR.DATA_NOT_FOUND, message: "No stop with that ID" }));

        const stopName = rows[0].stop_name;

        return res.status(200).json({ success: true, result: stopName })
    } catch (e) {
        console.log(e);
        return res.status(500).json({ success: false, error: ERROR.INTERNAL_ERROR, message: "Internal Server Error" });
    } finally {
        if (conn) conn.release();
    }
})

app.get("/stops/:stop_name/vehicles", async (req, res) => {
    const stop_name = decodeURIComponent(req.params.stop_name);

    let conn;
    try {
        conn = await dbPool.getConnection();

        // First get stop IDs (fast, indexed)
        const stops = await conn.query(
            `SELECT stop_id FROM stops
             WHERE stop_name = ?
             OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
             OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
            [stop_name, stop_name, stop_name]
        );

        if (!stops.length) {
            return res.status(404).json({ success: false, error: ERROR.DATA_NOT_FOUND, message: "Station does not serve any routes!" });
        }

        const stopIds = stops.map(s => s.stop_id);
        const placeholders = stopIds.map(() => '?').join(',');

        // Then query routes separately using the stop IDs
        const rows = await conn.query(`
            SELECT r.route_type, r.route_short_name
            FROM stop_times st
            JOIN trips t ON st.trip_id = t.trip_id
            JOIN routes r ON t.route_id = r.route_id
            WHERE st.stop_id IN (${placeholders})
            AND r.route_type IS NOT NULL
            AND r.route_short_name IS NOT NULL
            GROUP BY r.route_type, r.route_short_name
        `, stopIds);

        let vehicles = [...new Set(rows.map(v => getVehicleString(v.route_type, v.route_short_name)))];

        return res.status(200).json({ success: true, result: vehicles });
    } catch (e) {
        console.log(e);
        return res.status(500).json({ success: false, error: ERROR.INTERNAL_ERROR, message: "Internal Server Error" });
    } finally {
        if (conn) conn.release(); // always releases even on error
    }
});

app.get("/debug-times/", async (req, res) => {
    const stopName = req.query.stop;
    let conn;
    try {
        conn = await dbPool.getConnection();
        const rows = await conn.query(`
            SELECT 
                st.departure_time,
                HEX(st.departure_time) AS hex_time,
                LENGTH(st.departure_time) AS len
            FROM stop_times st
            JOIN stops s ON st.stop_id = s.stop_id
            WHERE s.stop_name = ?
            LIMIT 30
        `, [stopName]);
        return res.json(rows);
    } finally {
        if (conn) conn.release();
    }
});

app.get("/debug-trip/", async (req, res) => {
    const date = req.query.date; // the date you're requesting e.g. 2026-02-22 (Sunday)
    const stopName = req.query.stop;

    const prevDateObj = new Date(date);
    prevDateObj.setDate(prevDateObj.getDate() - 1);
    const prevDate = prevDateObj.toISOString().slice(0, 10);

    let conn;
    try {
        conn = await dbPool.getConnection();

        // Check exactly what the WHERE clause evaluates to for this trip on both days
        const rows = await conn.query(`
            SELECT 
                ? AS queried_date,
                ? AS prev_date,
                t.trip_id,
                t.service_id,
                c.monday, c.tuesday, c.wednesday, c.thursday, c.friday, c.saturday, c.sunday,
                DATE_FORMAT(c.start_date, '%Y-%m-%d') AS start_date,
                DATE_FORMAT(c.end_date, '%Y-%m-%d') AS end_date,
                cd.date AS cd_date,
                cd.exception_type,
                DATE_FORMAT(cd.date, '%Y-%m-%d') AS cd_date_formatted,
                DATE_FORMAT(cd.date, '%Y-%m-%d') = ? AS cd_matches_prevdate,
                DATE_FORMAT(c.start_date, '%Y-%m-%d') <= ? AS start_ok,
                DATE_FORMAT(c.end_date, '%Y-%m-%d') >= ? AS end_ok,
                c.saturday AS sat_flag
            FROM trips t
            LEFT JOIN calendar c ON t.service_id = c.service_id
            LEFT JOIN calendar_dates cd ON t.service_id = cd.service_id
                AND DATE_FORMAT(cd.date, '%Y-%m-%d') = ?
            WHERE t.trip_id = '480415979'
        `, [date, prevDate, prevDate, prevDate, prevDate, prevDate]);

        const safe = JSON.parse(JSON.stringify(rows, (_, v) =>
            typeof v === 'bigint' ? Number(v) : v
        ));

        return res.json(safe);
    } finally {
        if (conn) conn.release();
    }
});

app.get("/departures/", async (req, res) => {
    const stopName = req.query.stop;
    const weekday = req.query.weekday.toLowerCase();
    const date = req.query.date;       // YYYY-MM-DD
    const time = req.query.time;

    console.log(stopName);

    const departures = await getDeparturesForStop(stopName, weekday, date, time);

    if (!departures.success) {
        return res.sendStatus(departures.error);
    }

    return res.status(200).json(departures);
});

app.post("/refresh/", async (req, res) => {
    const { stops, routes, delayed } = req.body;

    const fullDate = getLocalDateTime();
    const weekday = fullDate.weekday.toLowerCase();
    const date = fullDate.date;
    const time = fullDate.time;

    // Fetch departures for stops
    const stopResults = await Promise.all(
        stops.map(stopName =>
            getDeparturesForStop(stopName, weekday, date, time)
        )
    );

    // Fetch departures for routes
    const routeResults = await Promise.all(
        routes.map(route =>
            getDeparturesForRoute(route.id, route.start_stop, weekday, date, time, route.direction)
        )
    );

    // Fetch delayed trips
    const delayedResults = await Promise.all(
        delayed.map(trip =>
            getDepartureForTrip(trip.id, trip.start_stop)
        )
    );

    // Filter successful results
    const successfulStops = stopResults.filter(r => r.success);
    const successfulRoutes = routeResults.filter(r => r.success);
    const successfulDelayed = delayedResults.filter(r => r.success);

    // Combine all departures
    let allDepartures = [
        ...successfulStops.flatMap(r =>
            r.departures.map(dep => ({
                ...dep,
                stationName: r.stop_name
            }))
        ),
        ...successfulRoutes.flatMap((r, i) => {
            const stopNameForRoute = routes[i].start_stop;
            return r.departures.map(dep => ({
                ...dep,
                stationName: stopNameForRoute,
                routeId: r.route_id
            }));
        }),
        ...successfulDelayed.flatMap((r, i) => {
            const stopNameForTrip = delayed[i].start_stop;
            return r.departures.map(dep => ({
                ...dep,
                stationName: stopNameForTrip
            }));
        })
    ];

    // Sort by departure time
    const toMinutes = (d) => {
        const [hh, mm] = d.departure_time.split(':').map(n => Number(n));
        return hh * 60 + mm;
    };
    allDepartures.sort((a, b) => toMinutes(a) - toMinutes(b));

    const seen = new Set();

    allDepartures = allDepartures.filter(dep => {
        const key = `${dep.trip_id}-${dep.stationName}-${dep.departure_time}`;

        if (seen.has(key)) {
            return false;
        }

        seen.add(key);
        return true;
    });

    // Limit to first 10 departures
    allDepartures = allDepartures.slice(0, 10);

    // Prepare array for new getDelays function
    const tripIdsWithStops = allDepartures.map(dep => ({
        tripId: dep.trip_id,
        stopIdOrName: dep.stationName
    }));

    // Fetch delays for the correct stop
    const delayResults = await getDelays(tripIdsWithStops);

    // Fetch important stops and apply delays
    allDepartures = await Promise.all(
        allDepartures.map(async dep => {
            const delay = delayResults[dep.trip_id]?.minutes || 0;
            const importantStopsResult = await getImportantStops(dep.trip_id, dep.stationName);

            return {
                ...dep,
                delay,
                importantStops: importantStopsResult.success ? importantStopsResult.result : []
            };
        })
    );

    return res.json({ success: true, departures: allDepartures });
});

app.get("/trips/:trip_id/stops/", async (req, res) => {
    const trip_id = req.params.trip_id
    const start_stop = req.query.start_stop;

    if (!trip_id) return res.status(400).json({ success: false, error: ERROR.MISSING_DATA, message: "trip_id not provided" });

    let stations = await getStationsAlongJourney(trip_id, start_stop);

    if (!stations) return res.status(500).json({ success: false, error: ERROR.INTERNAL_ERROR, message: "Internal Server Error" });
    
    return res.status(200).json({ success: true, result: stations });
});

app.get("/trips/:trip_id/important_stops", async (req, res) => {
    const trip_id = req.params.trip_id;
    const start_stop = req.query.start_stop;

    const result = await getImportantStops(trip_id, start_stop);

    if (!result.success) {
        return res.status(result.httpCode).json({ success: false, error: result.error, message: result.message });
    }

    return res.status(200).json({ success: true, result: result.result })
});

app.get("/trips/:trip_id/vehicle", async (req, res) => {
    const trip_id = req.params.trip_id;
    if (!trip_id) return res.status(400).json({ success: false, error: ERROR.MISSING_DATA, message: "trip-id not provided"});

    let conn;
    try {
        conn = await dbPool.getConnection();

        const trips = await conn.query(`SELECT * FROM trips WHERE trip_id=?`, [trip_id]);
        if (trips.length <= 0) 
            return res.status(404).json({ success: false, error: ERROR.DATA_NOT_FOUND, message: "No trip with this ID" });

        const routeRow = await conn.query(`SELECT route_short_name, route_type FROM routes WHERE route_id=?`, [trips[0].route_id]);
        if (routeRow.length <= 0) 
            return res.status(404).json({ success: false, error: ERROR.DATA_NOT_FOUND, message: "No route found for this trip" });

        const vehicleString = getVehicleString(routeRow[0].route_type, routeRow[0].route_short_name);

        return res.status(200).json({ success: true, vehicle: vehicleString });

    } catch (e) {
        console.error(e);
        return res.status(500).json({ success: false, error: ERROR.INTERNAL_ERROR, message: "Internal Server Error" });
    } finally {
        if (conn) conn.release();
    }
});

app.get("/trips/:trip_id/delay", async (req, res) => {
    const trip_id = req.params.trip_id;

    const result = await getDelay(trip_id);

    if (!result.success) {
        return res.status(result.httpCode).json({ success: false, error: result.error, message: result.message });
    }

    return res.status(200).json({ success: true, minutes: result.minutes });
});

app.get("/routes/:route_id/vehicle", async (req, res) => {
    const route_id = req.params.route_id;

    if (!route_id) return res.status(400).json({ success: false, error: ERROR.MISSING_DATA, message: "route-id not provided"});

    const vehicle = await getVehicle(route_id);
    if (!vehicle) return res.status(500).json({ success: false, error: ERROR.INTERNAL_ERROR, message: "Internal Server Error" });
    const vehicleString = getVehicleString(vehicle);
})

app.get("/routes/search", async (req, res) => {
    const query = req.query.q;
    const stopName = req.query.stop;

    if (!query || !stopName) {
        return res.status(400).json({
            success: false,
            error: ERROR.MISSING_DATA,
            message: "Query or Stop missing!"
        });
    }

    let conn;
    try {
        conn = await dbPool.getConnection();

        // get stop IDs
        const stops = await conn.query(
            `SELECT stop_id FROM stops
             WHERE stop_name = ?
                OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
            [stopName, stopName, stopName]
        );

        if (!stops.length) {
            return res.status(404).json({
                success: false,
                error: ERROR.DATA_NOT_FOUND,
                message: "Stop does not exist"
            });
        }

        const stopIds = stops.map(s => s.stop_id);
        const inPlaceholders = stopIds.map(() => '?').join(',');

        // extract prefix and numeric part
        const match = query.match(/^([a-zA-Z]*)(\d+)$/);
        const prefix = match ? match[1].toUpperCase() : '';
        const number = match ? match[2] : query.replace(/\D/g, '');

        let sql, params;

        // Build the main query including first and last stop
        const stopSelection = `
            JOIN (
                SELECT st.trip_id, s.stop_name AS last_stop_name
                FROM stop_times st
                JOIN stops s ON st.stop_id = s.stop_id
                WHERE st.stop_sequence = (
                    SELECT MAX(st2.stop_sequence)
                    FROM stop_times st2
                    WHERE st2.trip_id = st.trip_id
                )
            ) AS lastStops ON lastStops.trip_id = t.trip_id
            JOIN (
                SELECT st.trip_id, s.stop_name AS start_stop
                FROM stop_times st
                JOIN stops s ON st.stop_id = s.stop_id
                WHERE st.stop_sequence = (
                    SELECT MIN(st2.stop_sequence)
                    FROM stop_times st2
                    WHERE st2.trip_id = st.trip_id
                )
            ) AS firstStops ON firstStops.trip_id = t.trip_id
        `;

        if (prefix) {
            sql = `
                SELECT 
                    r.route_short_name,
                    r.route_type,
                    r.route_id,
                    MIN(t.trip_id) AS trip_id,
                    lastStops.last_stop_name AS trip_headsign,
                    firstStops.start_stop
                FROM stop_times st
                JOIN trips t ON st.trip_id = t.trip_id
                JOIN routes r ON t.route_id = r.route_id
                ${stopSelection}
                WHERE st.stop_id IN (${inPlaceholders})
                AND (
                    UPPER(r.route_short_name) = ? OR r.route_short_name = ?
                )
                AND st.trip_id NOT IN (
                    SELECT st2.trip_id
                    FROM stop_times st2
                    WHERE st2.stop_id IN (${inPlaceholders})
                      AND st2.stop_sequence = (
                          SELECT MAX(st3.stop_sequence)
                          FROM stop_times st3
                          WHERE st3.trip_id = st2.trip_id
                      )
                )
                GROUP BY r.route_id, lastStops.last_stop_name, firstStops.start_stop
            `;
            params = [...stopIds, `${prefix}${number}`, number, ...stopIds];
        } else {
            sql = `
                SELECT 
                    r.route_short_name,
                    r.route_type,
                    r.route_id,
                    MIN(t.trip_id) AS trip_id,
                    lastStops.last_stop_name AS trip_headsign,
                    firstStops.start_stop
                FROM stop_times st
                JOIN trips t ON st.trip_id = t.trip_id
                JOIN routes r ON t.route_id = r.route_id
                ${stopSelection}
                WHERE st.stop_id IN (${inPlaceholders})
                AND CAST(REGEXP_REPLACE(r.route_short_name, '^[^0-9]*', '') AS UNSIGNED) = ?
                AND st.trip_id NOT IN (
                    SELECT st2.trip_id
                    FROM stop_times st2
                    WHERE st2.stop_id IN (${inPlaceholders})
                      AND st2.stop_sequence = (
                          SELECT MAX(st3.stop_sequence)
                          FROM stop_times st3
                          WHERE st3.trip_id = st2.trip_id
                      )
                )
                GROUP BY r.route_id, lastStops.last_stop_name, firstStops.start_stop
            `;
            params = [...stopIds, number, ...stopIds];
        }

        const rows = await conn.query(sql, params);

        // Map rows with vehicle type
        const routes = rows.map(d => ({
            ...d,
            vehicle: getVehicleString(d.route_type, d.route_short_name),
            trip_headsign: d.trip_headsign || null,
            start_stop: d.start_stop || null
        }));

        return res.status(200).json({ success: true, routes });
    } catch (e) {
        console.log(e);
        return res.status(500).json({
            success: false,
            error: ERROR.INTERNAL_ERROR,
            message: "Internal Server Error"
        });
    } finally {
        if (conn) conn.release();
    }
});

async function getDeparturesForStop(stopName, weekday, date, time) {
    if (!stopName || !weekday || !date || !time) {
        return { success: false, httpCode: 400, message: "Missing data", error: ERROR.MISSING_DATA };
    }

    const VALID_WEEKDAYS = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    if (!VALID_WEEKDAYS.includes(weekday)) {
        return { success: false, httpCode: 400, message: "Invalid weekday", error: ERROR.MISSING_DATA };
    }

    const normTime = t => {
        const [hh, mm, ss] = t.split(':').map(Number);
        const h = hh >= 24 ? hh - 24 : hh;
        return `${String(h).padStart(2,'0')}:${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`;
    };

    const toPrevWeekday = wd => VALID_WEEKDAYS[(VALID_WEEKDAYS.indexOf(wd)+6)%7];

    const prevDateObj = new Date(date);
    prevDateObj.setDate(prevDateObj.getDate()-1);
    const prevDate = prevDateObj.toISOString().slice(0,10);
    const prevWeekday = toPrevWeekday(weekday);

    const [reqHH, reqMM] = time.split(':').map(Number);
    const requestedMinutes = reqHH*60 + reqMM;

    let conn;
    try {
        conn = await dbPool.getConnection();

        const stops = await conn.query(
            `SELECT stop_id FROM stops
             WHERE stop_name = ?
                OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
            [stopName, stopName, stopName]
        );

        if (!stops.length) return { success:false, httpCode:404, message:"Stop does not exist", error:ERROR.DATA_NOT_FOUND };

        const stopIds = stops.map(s=>s.stop_id);
        const inPlaceholders = stopIds.map(()=>'?').join(',');

        const buildSql = wd => `
            SELECT st.stop_id, st.trip_id, st.stop_sequence,
                   CAST(TRIM(st.arrival_time) AS CHAR) AS arrival_time,
                   CAST(TRIM(st.departure_time) AS CHAR) AS departure_time,
                   CAST(SUBSTRING_INDEX(TRIM(st.departure_time), ':', 1) AS UNSIGNED)*60 +
                   CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(st.departure_time), ':', 2), ':', -1) AS UNSIGNED) AS dep_minutes,
                   t.trip_headsign, t.trip_short_name, t.route_id,
                   r.route_short_name, r.route_long_name, r.route_type
            FROM stop_times st
            JOIN trips t ON st.trip_id = t.trip_id
            JOIN routes r ON t.route_id = r.route_id
            LEFT JOIN calendar c ON t.service_id = c.service_id
            LEFT JOIN calendar_dates cd ON t.service_id = cd.service_id AND cd.date = ?
            LEFT JOIN (
                SELECT st2.trip_id
                FROM stop_times st2
                JOIN (
                    SELECT trip_id, MAX(stop_sequence) AS max_seq
                    FROM stop_times
                    GROUP BY trip_id
                ) last_stops ON st2.trip_id = last_stops.trip_id AND st2.stop_sequence = last_stops.max_seq
                WHERE st2.stop_id IN (${inPlaceholders})
            ) last_trip_stops ON st.trip_id = last_trip_stops.trip_id
            WHERE st.stop_id IN (${inPlaceholders})
              AND last_trip_stops.trip_id IS NULL
              AND (
                  (cd.date IS NOT NULL AND cd.exception_type = 1)
                  OR (cd.date IS NULL AND c.start_date <= ? AND c.end_date >= ? AND c.${wd} = 1)
              )
            ORDER BY dep_minutes
        `;

        const buildParams = d => [d, ...stopIds, ...stopIds, d, d];

        const [departures, prevDepartures] = await Promise.all([
            conn.query(buildSql(weekday), buildParams(date)),
            conn.query(buildSql(prevWeekday), buildParams(prevDate))
        ]);

        const filterResults = (rows, includePostMidnight=false) => rows.filter(d => {
            const mins = Number(d.dep_minutes);
            if (includePostMidnight) return mins >= 24*60 && (mins - 24*60) >= requestedMinutes;
            return mins < 24*60 ? mins >= requestedMinutes : (mins - 24*60) >= requestedMinutes;
        });

        const sameDayResults = filterResults(departures);
        const prevDayResults = filterResults(prevDepartures, true);

        const toDisplayMinutes = m => Number(m) >= 24*60 ? Number(m)-24*60 : Number(m);

        const combined = [...prevDayResults, ...sameDayResults].sort((a,b)=>toDisplayMinutes(a.dep_minutes)-toDisplayMinutes(b.dep_minutes));

        const nullHeadsignTrips = combined.filter(d=>!d.trip_headsign).map(d=>d.trip_id);
        let lastStopNames = {};
        if (nullHeadsignTrips.length) {
            const placeholders = nullHeadsignTrips.map(()=>'?').join(',');
            const lastStops = await conn.query(
                `SELECT st.trip_id, s.stop_name
                 FROM stop_times st
                 JOIN stops s ON st.stop_id = s.stop_id
                 WHERE st.trip_id IN (${placeholders})
                   AND st.stop_sequence = (SELECT MAX(st2.stop_sequence) FROM stop_times st2 WHERE st2.trip_id = st.trip_id)`,
                nullHeadsignTrips
            );
            lastStops.forEach(r=>lastStopNames[r.trip_id] = r.stop_name);
        }

        const getDisplayName = (type, short, tripShort) => {
            if ((type === 101 || type === 102) && tripShort) return String(parseInt(tripShort,10));
            return short;
        };

        const mapRow = ({dep_minutes, ...d}) => {
            const headsign = d.trip_headsign || lastStopNames[d.trip_id] || null;
            const row = {
                ...d,
                arrival_time: normTime(d.arrival_time),
                departure_time: normTime(d.departure_time),
                vehicle: getVehicleString(d.route_type, d.route_short_name, d.trip_id),
                route_short_name: getDisplayName(d.route_type, d.route_short_name, d.trip_short_name)
            };
            if (headsign) row.trip_headsign = headsign;
            else delete row.trip_headsign;
            return row;
        };

        return { success:true, stop_name:stopName, stop_ids:stopIds, departures:combined.map(mapRow) };

    } catch(e) {
        console.error(e);
        return { success:false, httpCode:500, message:"Internal server error", error:ERROR.INTERNAL_ERROR };
    } finally { if (conn) conn.release(); }
}

async function getDeparturesForRoute(routeId, stopName, weekday, date, time, direction) {
    if (!routeId || !stopName || !weekday || !date || !time) {
        return { success: false, httpCode: 400, message: "No date provided", error: ERROR.MISSING_DATA };
    }

    const VALID_WEEKDAYS = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday'];
    if (!VALID_WEEKDAYS.includes(weekday)) return { success: false, httpCode: 400, message: "Invalid weekday", error: ERROR.MISSING_DATA };

    const normTime = (t) => {
        const [hh, mm, ss] = t.split(':').map(Number);
        const h = hh >= 24 ? hh - 24 : hh;
        return `${String(h).padStart(2,'0')}:${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`;
    };

    const toPrevWeekday = (wd) => VALID_WEEKDAYS[(VALID_WEEKDAYS.indexOf(wd)+6)%7];

    const prevDateObj = new Date(date);
    prevDateObj.setDate(prevDateObj.getDate()-1);
    const prevDate = prevDateObj.toISOString().slice(0,10);
    const prevWeekday = toPrevWeekday(weekday);

    const [reqHH, reqMM] = time.split(':').map(Number);
    const requestedMinutes = reqHH*60 + reqMM;

    let conn;
    try {
        conn = await dbPool.getConnection();

        // Get stop IDs for stopName (handle parent/child stations)
        const stops = await conn.query(
            `SELECT stop_id FROM stops
             WHERE stop_name = ?
                OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
            [stopName, stopName, stopName]
        );
        if (!stops.length) return { success:false, httpCode: 404, message: "Stop does not exist", error: ERROR.DATA_NOT_FOUND };

        const stopIds = stops.map(s => s.stop_id);
        const inPlaceholders = stopIds.map(()=>'?').join(',');

        const buildSql = (wd) => `
            SELECT 
                st.stop_id,
                st.trip_id,
                st.stop_sequence,
                CAST(TRIM(st.arrival_time) AS CHAR) AS arrival_time,
                CAST(TRIM(st.departure_time) AS CHAR) AS departure_time,
                CAST(SUBSTRING_INDEX(TRIM(st.departure_time), ':', 1) AS UNSIGNED)*60 +
                CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(st.departure_time), ':', 2), ':', -1) AS UNSIGNED) AS dep_minutes,
                t.trip_headsign,
                t.trip_short_name,
                t.route_id,
                r.route_short_name,
                r.route_long_name,
                r.route_type
            FROM stop_times st
            JOIN trips t ON st.trip_id = t.trip_id
            JOIN routes r ON t.route_id = r.route_id
            LEFT JOIN calendar c ON t.service_id = c.service_id
            LEFT JOIN calendar_dates cd ON t.service_id = cd.service_id
                AND DATE_FORMAT(cd.date,'%Y-%m-%d') = ?
            WHERE t.route_id = ?
              AND st.stop_id IN (${inPlaceholders})
              AND (
                  (cd.date IS NOT NULL AND cd.exception_type = 1)
                  OR (cd.date IS NULL
                      AND DATE_FORMAT(c.start_date,'%Y-%m-%d') <= ?
                      AND DATE_FORMAT(c.end_date,'%Y-%m-%d') >= ?
                      AND c.${wd} = 1
                     )
              )
              AND st.trip_id NOT IN (
                  SELECT st2.trip_id
                  FROM stop_times st2
                  WHERE st2.stop_id IN (${inPlaceholders})
                    AND st2.stop_sequence = (
                        SELECT MAX(st3.stop_sequence)
                        FROM stop_times st3
                        WHERE st3.trip_id = st2.trip_id
                    )
              )
            ORDER BY dep_minutes
        `;

        const buildParams = (d) => [d, routeId, ...stopIds, d, d, ...stopIds];

        // Run queries for requested day + previous day
        const [departures, prevDepartures] = await Promise.all([
            conn.query(buildSql(weekday), buildParams(date)),
            conn.query(buildSql(prevWeekday), buildParams(prevDate))
        ]);

        // Filter by requested time (handle post-midnight departures)
        const sameDayResults = departures.filter(d => {
            const mins = Number(d.dep_minutes);
            // Exclude previous-day trips mistakenly included
            return mins < 24*60 && mins >= requestedMinutes;
        });

        const prevDayResults = prevDepartures.filter(d => {
            const mins = Number(d.dep_minutes);
            // Only include trips that are after midnight (24:00+) on previous service day
            return mins >= 24*60 && (mins - 24*60) >= requestedMinutes;
        });

        let combined = [...prevDayResults, ...sameDayResults].sort((a,b)=>{
            const m = (x) => Number(x.dep_minutes) >= 24*60 ? Number(x.dep_minutes)-24*60 : Number(x.dep_minutes);
            return m(a)-m(b);
        });

        // Fill missing trip_headsign from last stop
        const nullHeadsignTrips = combined.filter(d=>!d.trip_headsign).map(d=>d.trip_id);
        let lastStopNames = {};
        if (nullHeadsignTrips.length > 0) {
            const placeholders = nullHeadsignTrips.map(()=>'?').join(',');
            const lastStops = await conn.query(
                `SELECT st.trip_id, s.stop_name
                 FROM stop_times st
                 JOIN stops s ON st.stop_id = s.stop_id
                 WHERE st.trip_id IN (${placeholders})
                   AND st.stop_sequence = (
                       SELECT MAX(st2.stop_sequence) FROM stop_times st2 WHERE st2.trip_id = st.trip_id
                   )`,
                nullHeadsignTrips
            );
            lastStops.forEach(r=>lastStopNames[r.trip_id]=r.stop_name);
        }

        const mapRow = ({ dep_minutes, ...d }) => ({
            ...d,
            arrival_time: normTime(d.arrival_time),
            departure_time: normTime(d.departure_time),
            vehicle: getVehicleString(d.route_type, d.route_short_name, d.trip_id),
            trip_headsign: d.trip_headsign || lastStopNames[d.trip_id] || null,
        });

        // --- Filter by direction if provided ---
        if (direction.length > 0) {
            if (!Array.isArray(direction)) direction = [direction];
        
            combined = combined.filter(d => {
                const lastStop = lastStopNames[d.trip_id] || d.trip_headsign;
                return direction.includes(lastStop);
            });
        }

        return {
            success: true,
            route_id: routeId,
            stop_name: stopName,
            stop_ids: stopIds,
            departures: combined.map(mapRow)
        };

    } catch(e){
        console.error(e);
        return { success:false, httpCode: 500, message: "Internal Server Error", error: ERROR.INTERNAL_ERROR };
    } finally {
        if (conn) conn.release();
    }
}

async function getDepartureForTrip(tripId, stopName) {
    if (!tripId || !stopName) return { success: false, httpCode: 400, message: "Missing stop/trip", error: ERROR.MISSING_DATA };

    let conn;
    try {
        conn = await dbPool.getConnection();

        const stops = await conn.query(
            `SELECT stop_id FROM stops
             WHERE stop_name = ?
                OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
            [stopName, stopName, stopName]
        );
        if (!stops.length) return { success: false, httpCode: 404, message: "Stop does not exist", error: ERROR.DATA_NOT_FOUND };

        const stopIds = stops.map(s=>s.stop_id);
        const inPlaceholders = stopIds.map(()=>'?').join(',');

        const rows = await conn.query(`
            SELECT
                st.stop_id,
                st.trip_id,
                st.stop_sequence,
                CAST(TRIM(st.arrival_time) AS CHAR) AS arrival_time,
                CAST(TRIM(st.departure_time) AS CHAR) AS departure_time,
                CAST(SUBSTRING_INDEX(TRIM(st.departure_time), ':', 1) AS UNSIGNED)*60 +
                CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(TRIM(st.departure_time), ':', 2), ':', -1) AS UNSIGNED) AS dep_minutes,
                t.trip_headsign,
                t.trip_short_name,
                t.route_id,
                r.route_short_name,
                r.route_long_name,
                r.route_type
            FROM trips t
            JOIN routes r ON t.route_id = r.route_id
            JOIN stop_times st ON t.trip_id = st.trip_id AND st.stop_id IN (${inPlaceholders})
            WHERE t.trip_id = ?`,
            [...stopIds, tripId]
        );

        // Fill missing headsign from last stop
        const nullHeadsignTrips = rows.filter(d=>!d.trip_headsign).map(d=>d.trip_id);
        let lastStopNames = {};
        if (nullHeadsignTrips.length>0){
            const placeholders = nullHeadsignTrips.map(()=>'?').join(',');
            const lastStops = await conn.query(
                `SELECT st.trip_id, s.stop_name
                 FROM stop_times st
                 JOIN stops s ON st.stop_id = s.stop_id
                 WHERE st.trip_id IN (${placeholders})
                   AND st.stop_sequence = (
                       SELECT MAX(st2.stop_sequence) FROM stop_times st2 WHERE st2.trip_id = st.trip_id
                   )`,
                nullHeadsignTrips
            );
            lastStops.forEach(r=>lastStopNames[r.trip_id]=r.stop_name);
        }

        const normTime = (t) => {
            const [hh, mm, ss] = t.split(':').map(Number);
            const h = hh >= 24 ? hh-24 : hh;
            return `${String(h).padStart(2,'0')}:${String(mm).padStart(2,'0')}:${String(ss).padStart(2,'0')}`;
        };

        const mapped = rows.map(({ dep_minutes, ...d }) => ({
            ...d,
            arrival_time: normTime(d.arrival_time),
            departure_time: normTime(d.departure_time),
            vehicle: getVehicleString(d.route_type, d.route_short_name, d.trip_id),
            trip_headsign: d.trip_headsign || lastStopNames[d.trip_id] || null
        }));

        return { success:true, departures: mapped };

    } catch(e){
        console.error(e);
        return { success: false, httpCode: 500, message: "Internal Server Error", error: ERROR.INTERNAL_ERROR };
    } finally {
        if (conn) conn.release();
    }
}

async function fetchAndSearch(url, trip_id) {
    try {
        const response = await fetch(url);
        if (!response.ok) return null;

        const buffer = await response.arrayBuffer();

        const feed =
            GtfsRealtimeBindings.transit_realtime.FeedMessage.decode(
            new Uint8Array(buffer)
        );

        const entity = feed.entity.find((e) => {
            const id = e.tripUpdate?.trip?.tripId;
            if (id && id.startsWith(trip_id)) {
                console.log("MATCHED:", id, "for search:", trip_id);
                return true;
            }
            return false;
        });
        if (!entity) return null;

        const stopUpdate = entity.tripUpdate.stopTimeUpdate?.[0];
        const delaySec = stopUpdate?.arrival?.delay ?? stopUpdate?.departure?.delay ?? null;
        console.log("Trip:", trip_id, "stopUpdate:", JSON.stringify(stopUpdate));
        console.log("delaySec:", delaySec);

        //const stopUpdate = entity.tripUpdate.stopTimeUpdate?.[0];
        const delay =
            stopUpdate?.arrival?.delay ??
            stopUpdate?.departure?.delay ??
            null;

        return {
            feedUrl: url,
            delay,
        }

    } catch (err) {
        return null; // ignore broken feed
    }
}

async function getDelay(trip_id) {
    console.log("fetching delay for: " + trip_id);

    try {
        const [feedNameUpper, patchedTripId] = trip_id.split("_");

        const feedName = feedNameUpper.toLowerCase();
        
        const feedUrl = FEEDS[feedName];

        if (!feedUrl) {
            return { success: false, httpCode: 404, message: "Feed not found", error: ERROR.DATA_NOT_FOUND};
        }
        
        const found = await fetchAndSearch(feedUrl, patchedTripId);

        if (!found) {
            return { success: false, httpCode: 404, message: "No delay found", error: ERROR.DATA_NOT_FOUND};
        }

        if (found.delay == null) {
            return { success: false, httpCode: 404, message: "No delay found", error: ERROR.DATA_NOT_FOUND};
        }

        const minutes = Math.round(found.delay / 60);
        return { success: true, minutes: minutes };

    } catch (err) {
        console.error("Error:", err.message);
        return { success: false, httpCode: 500, message: "Internal Server Error", error: ERROR.INTERNAL_ERROR};
    }
}

async function getDelays(tripIdsWithStops) {
    let conn;
    try {
        conn = await dbPool.getConnection();

        const tripsByFeed = {}; 
        const stopNameToIds = {};

        // Pre-fetch stop IDs for each unique stop name
        const uniqueStops = [...new Set(tripIdsWithStops.map(t => t.stopIdOrName))];
        for (const stopName of uniqueStops) {
            const stops = await conn.query(
                `SELECT stop_id FROM stops
                 WHERE stop_name = ?
                    OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                    OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
                [stopName, stopName, stopName]
            );

            if (stops.length) {
                stopNameToIds[stopName] = stops.map(s => {
                    const parts = s.stop_id.split("_");
                    return parts[parts.length - 1]; // strip prefix
                });
            } else {
                stopNameToIds[stopName] = [];
            }
        }

        // Group trips by feed
        for (const { tripId } of tripIdsWithStops) {
            const [feedNameUpper, ...rest] = tripId.split("_");
            const feedName = feedNameUpper.toLowerCase();
            const patchedTripId = rest.join("_"); // everything after first "_"
            if (!tripsByFeed[feedName]) tripsByFeed[feedName] = [];
            tripsByFeed[feedName].push({ fullId: tripId, patchedId: patchedTripId });
        }

        const results = {}; 

        await Promise.all(Object.entries(tripsByFeed).map(async ([feedName, trips]) => {
            const feedUrl = FEEDS[feedName];
            if (!feedUrl) {
                trips.forEach(t => results[t.fullId] = { success: false, minutes: 0 });
                return;
            }

            try {
                const response = await fetch(feedUrl);
                if (!response.ok) {
                    console.log(`Feed ${feedName} fetch failed: ${response.status}`);
                    trips.forEach(t => results[t.fullId] = { success: false, minutes: 0 });
                    return;
                }

                const buffer = await response.arrayBuffer();
                const feed =
                    GtfsRealtimeBindings.transit_realtime.FeedMessage.decode(
                        new Uint8Array(buffer)
                    );

                for (const { fullId, patchedId } of trips) {
                    const entity = Object.values(feed.entity).find(e =>
                        e.tripUpdate?.trip?.tripId?.startsWith(patchedId)
                    );

                    if (!entity) {
                        results[fullId] = { success: false, minutes: 0 };
                        continue;
                    }

                    const requestedStopName = tripIdsWithStops.find(t => t.tripId === fullId)?.stopIdOrName;
                    const stopIds = stopNameToIds[requestedStopName] || [];

                    // Match any stop ID in the feed
                    const stopUpdate = entity.tripUpdate.stopTimeUpdate?.find(s =>
                        stopIds.includes(s.stopId)
                    );

                    if (!stopUpdate) {
                        results[fullId] = { success: false, minutes: 0 };
                        continue;
                    }

                    const delaySec = stopUpdate?.arrival?.delay ?? stopUpdate?.departure?.delay ?? null;

                    if (delaySec == null) {
                        results[fullId] = { success: false, minutes: 0 };
                    } else {
                        results[fullId] = { success: true, minutes: Math.round(delaySec / 60) };
                    }
                }

            } catch (err) {
                trips.forEach(t => results[t.fullId] = { success: false, minutes: 0 });
            }
        }));
        return results;

    } catch (err) {
        console.error("Error in getDelays:", err);
        return {};
    } finally {
        if (conn) {
            await conn.release();
        }
    }
}

function getVehicleString(vehicle_id, routeShortName, trip_id="") {
    if (trip_id.toLowerCase().includes("lux")) return 'lux express';
    if (/^S\d/.test(routeShortName)) return 'suburban train';
    if (/^RE\d?/.test(routeShortName)) return 'regional train';
    if (/^RB\d?/.test(routeShortName)) return 'regional train';
    if (/^ICE\d?/.test(routeShortName)) return 'high speed train';
    if (/^EC\d?/.test(routeShortName)) return 'long distance train';
    // High speed / long distance / regional rail 100–199
    if (vehicle_id >= 100 && vehicle_id < 200) {
        switch(vehicle_id) {
            case 101: return "high speed train";
            case 102: return "long distance train";
            case 103: return "inter regional train";
            case 105: return "night train";
            case 106: return "regional train";
            case 107: return "tourist train";
            case 108: return "rail shuttle train";
            case 109: return "suburban train";
            default: return "train";
        }
    }

    // Coach services 200–299
    if (vehicle_id >= 200 && vehicle_id < 300) return "coach";

    // Urban rail 400–499
    if (vehicle_id >= 400 && vehicle_id < 500) {
        switch(vehicle_id) {
            case 401:
            case 402:
                return "metro";
            case 405:
                return "monorail";
            default:
                return "urban railway";
        }
    }

    // Bus services 700–799
    if (vehicle_id >= 700 && vehicle_id < 800) {
        switch(vehicle_id) {
            case 701: return "regional bus";
            case 702: return "express bus";
            case 705: return "night bus";
            case 714: return "rail replacement bus";
            default: return "bus";
        }
    }

    // Trolleybus 800–899
    if (vehicle_id >= 800 && vehicle_id < 900) return "trolleybus";

    // Tram / light rail 900–999
    if (vehicle_id >= 900 && vehicle_id < 1000) return "tram";

    //Ferroes 1200-1299
    if (vehicle_id >= 1200 && vehicle_id < 1300) return "ferry";

    // Aerial lifts 1300–1399
    if (vehicle_id >= 1300 && vehicle_id < 1400) return "aerial lift";

    // Funiculars 1400–1499
    if (vehicle_id >= 1400 && vehicle_id < 1500) return "funicular";

    // Default / standard vehicle types
    switch (vehicle_id) {
        case 0: return "tram";
        case 1: return "metro";
        case 2: return "train";
        case 3: return "bus";
        case 4: return "ferry";
        case 5: return "cable tram";
        case 6: return "gondola";
        case 7: return "funicular";
        case 11: return "trolleybus";
        case 12: return "monorail";
        default:
            console.log(vehicle_id); 
            return "unknown";
    }
}

function getVehicleCategory(vehicle_id) {
    if (vehicle_id >= 100 && vehicle_id < 200) {
        switch(vehicle_id) {
            case 101: return "high speed train";
            case 102: return "long distance train";
            case 103: return "inter regional train";
            case 105: return "night train";
            case 106: return "regional train";
            case 109: return "suburban train";
            default: return "train";
        }
    }

    // Coach services 200–299
    if (vehicle_id >= 200 && vehicle_id < 300) return "coach";

    // Urban rail 400–499
    if (vehicle_id >= 400 && vehicle_id < 500) {
        switch(vehicle_id) {
            case 401:
            case 402:
                return "metro";
            case 405:
                return "tram";
            default:
                return "metro";
        }
    }

    // Bus services 700–799
    if (vehicle_id >= 700 && vehicle_id < 800) {
        switch(vehicle_id) {
            case 701: return "regional bus";
            case 702: return "express bus";
            case 705: return "night bus";
            case 714: return "rail replacement bus";
            default: return "bus";
        }
    }

    // Trolleybus 800–899
    if (vehicle_id >= 800 && vehicle_id < 900) return "trolleybus";

    // Tram / light rail 900–999
    if (vehicle_id >= 900 && vehicle_id < 1000) return "tram";

    // Aerial lifts 1300–1399
    if (vehicle_id >= 1300 && vehicle_id < 1400) return "aerial lift";

    // Funiculars 1400–1499
    if (vehicle_id >= 1400 && vehicle_id < 1500) return "funicular";

    // Default / standard vehicle types
    switch (vehicle_id) {
        case 0: return "tram";
        case 1: return "metro";
        case 2: return "train";
        case 3: return "bus";
        case 4: return "ferry";
        case 5: return "cable tram";
        case 6: return "gondola";
        case 7: return "funicular";
        case 11: return "trolleybus";
        case 12: return "monorail";
        default: return "unknown";
    }
}

async function getVehicle(route_id) {
    let conn;
    try {
        conn = await dbPool.getConnection();
        const rows = await conn.query(`SELECT * FROM routes WHERE route_id=?`, [route_id]);
        if (rows.length <= 0) return false;
        return rows[0]; // return full row with route_type and route_short_name
    } catch (e) {
        console.error(e);
        return false;
    } finally {
        if (conn) conn.release();
    }
}

async function getStationsAlongJourney(trip_id, start_stop) {
    let conn;
    try {
        conn = await dbPool.getConnection();

        // Get stop IDs for start_stop name
        const stops = await conn.query(
            `SELECT stop_id FROM stops
             WHERE stop_name = ?
                OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
            [start_stop, start_stop, start_stop]
        );

        if (!stops.length) 
            return { success: false, httpCode: 404, message: "Stop does not exist", error: ERROR.DATA_NOT_FOUND };

        const stopIds = stops.map(s => s.stop_id);
        const inPlaceholders = stopIds.map(() => '?').join(',');

        let startStopSequence = 0;

        if (start_stop) {
            const stopSequenceRows = await conn.query(
                `SELECT st.stop_sequence
                 FROM stop_times st
                 WHERE st.trip_id = ?
                 AND st.stop_id IN (${inPlaceholders})
                 ORDER BY st.stop_sequence ASC
                 LIMIT 1`,
                [trip_id, ...stopIds]
            );

            if (stopSequenceRows.length > 0) {
                startStopSequence = stopSequenceRows[0].stop_sequence;
            }
        }

        // Fetch all stops after startStopSequence
        const rows = await conn.query(
            `SELECT 
                st.stop_sequence,
                st.arrival_time,
                st.departure_time,
                s.stop_id,
                s.stop_name
             FROM stop_times st
             JOIN stops s ON st.stop_id = s.stop_id
             WHERE st.trip_id = ?
               AND st.stop_sequence >= ?
             ORDER BY st.stop_sequence ASC`,
            [trip_id, startStopSequence]
        );

        return rows;
    } catch (e) {
        console.log(e);
        return false;
    } finally {
        if (conn) conn.release();
    }
}

async function getImportantStops(trip_id, start_stop) {
    let conn;
    try {
        conn = await dbPool.getConnection();

        let startSequence = null;

        if (start_stop) {
            const startStops = await conn.query(
                `SELECT stop_id FROM stops
                 WHERE stop_name = ?
                 OR parent_station IN (SELECT stop_id FROM stops WHERE stop_name = ?)
                 OR stop_id IN (SELECT parent_station FROM stops WHERE stop_name = ?)`,
                [start_stop, start_stop, start_stop]
            );

            if (startStops.length > 0) {
                const startStopIds = startStops.map(s => s.stop_id);
                const placeholders = startStopIds.map(() => '?').join(',');

                const seqResult = await conn.query(
                    `SELECT stop_sequence FROM stop_times
                     WHERE trip_id = ?
                     AND stop_id IN (${placeholders})
                     LIMIT 1`,
                    [trip_id, ...startStopIds]
                );

                if (seqResult.length > 0) {
                    startSequence = seqResult[0].stop_sequence;
                }
            }
        }

        const rows = await conn.query(`
            SELECT 
                st_trip.stop_sequence,
                s.stop_name,
                CAST(COUNT(DISTINCT r.route_id) AS UNSIGNED) AS route_count
            FROM stop_times st_trip
            JOIN stops s ON st_trip.stop_id = s.stop_id
            JOIN stop_times st_all ON s.stop_id = st_all.stop_id
            JOIN trips t_all ON st_all.trip_id = t_all.trip_id
            JOIN routes r ON t_all.route_id = r.route_id
            WHERE st_trip.trip_id = ?
            ${startSequence !== null ? `AND st_trip.stop_sequence > ${Number(startSequence)}` : ''}
            AND st_trip.stop_sequence != (
                SELECT MIN(stop_sequence) FROM stop_times WHERE trip_id = ?
            )
            AND st_trip.stop_sequence != (
                SELECT MAX(stop_sequence) FROM stop_times WHERE trip_id = ?
            )
            GROUP BY s.stop_id, s.stop_name
            ORDER BY route_count DESC
            LIMIT 2
        `, [trip_id, trip_id, trip_id]);

        const safeRows = rows.map(r => ({
            ...r,
            route_count: Number(r.route_count)
        }));

        safeRows.sort((a, b) => a.stop_sequence - b.stop_sequence);

        return { success: true, result: safeRows };

    } catch (e) {
        console.error(e);
        return { success: false, httpCode: 500, message: "Internal Server Error", error: ERROR.INTERNAL_ERROR };
    } finally {
        if (conn) conn.release();
    }
}

function parseGtfsTime(timeStr, dateStr) {
    let [hh, mm, ss] = timeStr.split(':').map(Number);
    let date = new Date(dateStr);
    if (hh >= 24) {
        hh -= 24;
        date.setDate(date.getDate() + 1);
    }
    date.setHours(hh, mm, ss);
    return date;
}

function getBerlinDateTime() {
    const now = new Date();

    const formatter = new Intl.DateTimeFormat('en-CA', {
        timeZone: 'Europe/Berlin',
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        weekday: 'long',
        hour12: false
    });

    const parts = formatter.formatToParts(now);

    const get = (type) => parts.find(p => p.type === type)?.value;

    return {
        date: `${get('year')}-${get('month')}-${get('day')}`, // yyyy-mm-dd
        time: `${get('hour')}:${get('minute')}:${get('second')}`, // hh:mm:ss
        weekday: get('weekday').toLowerCase() // monday, tuesday, ...
    };
}

function getLocalDateTime() {
    const now = new Date();

    const formatter = new Intl.DateTimeFormat('en-CA', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit',
        weekday: 'long',
        hour12: false
    });

    const parts = formatter.formatToParts(now);

    const get = (type) => parts.find(p => p.type === type)?.value;

    return {
        date: `${get('year')}-${get('month')}-${get('day')}`, // yyyy-mm-dd
        time: `${get('hour')}:${get('minute')}:${get('second')}`, // hh:mm:ss
        weekday: get('weekday').toLowerCase()
    };
}

app.listen(EXPRESS_PORT, () => {
  console.log(`Server running on http://localhost:${EXPRESS_PORT}`);
});