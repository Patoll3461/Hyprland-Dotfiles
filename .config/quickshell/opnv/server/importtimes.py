import csv
import pymysql

conn = pymysql.connect(
    host='localhost',
    user='opnv-user',
    password='HP5-udOdP+opnv',
    database='opnv',
    autocommit=True,
    local_infile=True
)
cursor = conn.cursor()

def import_stop_times_fast(csv_file_path, prefix=''):
    with open(csv_file_path, newline='', encoding='utf-8') as f:
        reader = csv.reader(f)
        headers = next(reader)

    col_list = ', '.join(f'@{h.strip()}' for h in headers)

    cursor.execute("DROP TEMPORARY TABLE IF EXISTS stop_times_raw")
    cursor.execute("""
        CREATE TEMPORARY TABLE stop_times_raw (
            trip_id VARCHAR(100),
            arrival_time VARCHAR(12),
            departure_time VARCHAR(12),
            stop_id VARCHAR(100),
            stop_sequence VARCHAR(50),
            stop_headsign VARCHAR(255),
            pickup_type VARCHAR(10),
            drop_off_type VARCHAR(10),
            shape_dist_traveled VARCHAR(20)
        )
    """)

    known = ['trip_id', 'arrival_time', 'departure_time', 'stop_id',
             'stop_sequence', 'stop_headsign', 'pickup_type', 'drop_off_type',
             'shape_dist_traveled']
    csv_headers = [h.strip() for h in headers]
    set_clause = ', '.join(
        f"{col} = @{col}" if col in csv_headers else f"{col} = NULL"
        for col in known
    )

    load_sql = f"""
        LOAD DATA LOCAL INFILE '{csv_file_path}'
        INTO TABLE stop_times_raw
        FIELDS TERMINATED BY ','
        ENCLOSED BY '"'
        LINES TERMINATED BY '\\n'
        IGNORE 1 ROWS
        ({col_list})
        SET {set_clause}
    """
    cursor.execute(load_sql)

    cursor.execute("SELECT COUNT(*) FROM stop_times_raw")
    print("Rows in raw table:", cursor.fetchone()[0])

    p = prefix
    trip_id_expr = f"CONCAT('{p}', trip_id)" if p else "trip_id"
    stop_id_expr = f"CONCAT('{p}', stop_id)" if p else "stop_id"

    cursor.execute(f"""
        INSERT IGNORE INTO stop_times (
            trip_id, arrival_time, departure_time, stop_id,
            stop_sequence, stop_headsign, pickup_type, drop_off_type, shape_dist_traveled
        )
        SELECT
            {trip_id_expr},
            arrival_time,
            departure_time,
            {stop_id_expr},
            CAST(stop_sequence AS UNSIGNED),
            NULLIF(stop_headsign, ''),
            CASE WHEN pickup_type = '' THEN 0 ELSE CAST(pickup_type AS UNSIGNED) END,
            CASE WHEN drop_off_type = '' THEN 0 ELSE CAST(drop_off_type AS UNSIGNED) END,
            NULLIF(shape_dist_traveled, '')
        FROM stop_times_raw
        WHERE stop_sequence REGEXP '^[0-9]+$'
    """)
        
    cursor.execute("SHOW WARNINGS LIMIT 10");
    print(cursor.fetchall())

    cursor.execute("SELECT COUNT(*) FROM stop_times")
    print(f"Total stop_times rows: {cursor.fetchone()[0]}")

    cursor.execute("SELECT ROW_COUNT()")
    print("Rows inserted:", cursor.fetchone()[0])

    cursor.execute("DROP TEMPORARY TABLE stop_times_raw")


cursor.execute("SET foreign_key_checks = 0")
cursor.execute("SET unique_checks = 0")

import_stop_times_fast("/home/patoll/.config/quickshell/opnv/server/gtfs/kaugliinid/stop_times.txt", prefix="kaugliinid_")

cursor.execute("SET foreign_key_checks = 1")
cursor.execute("SET unique_checks = 1")

cursor.close()
conn.close()