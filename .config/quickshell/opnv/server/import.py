import csv
import pymysql

conn = pymysql.connect(
    host='localhost',
    user='opnv-user',
    password='HP5-udOdP+opnv',
    database='opnv',
    autocommit=True
)
cursor = conn.cursor()

# Columns that contain IDs and need prefixing
ID_COLUMNS = {
    'stop_id', 'parent_station',           # stops
    'route_id', 'agency_id',               # routes
    'trip_id', 'service_id', 'shape_id',   # trips
    'block_id',                            # trips
}

def prefix_row(row, mapped_columns, prefix):
    """Apply prefix to ID columns in a row."""
    result = []
    for col in mapped_columns:
        val = row.get(col) or None
        if val and col in ID_COLUMNS:
            val = prefix + val
        result.append(val)
    return result

def import_gtfs_file(csv_file_path, table_name, table_columns, prefix=''):
    with open(csv_file_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        csv_columns = reader.fieldnames
        mapped_columns = [col for col in table_columns if col in csv_columns]

        if not mapped_columns:
            print(f"No matching columns found for {table_name}")
            return

        placeholders = ','.join(['%s'] * len(mapped_columns))
        cols_sql = ','.join(mapped_columns)
        sql = f"INSERT IGNORE INTO {table_name} ({cols_sql}) VALUES ({placeholders})"

        rows = []
        for row in reader:
            rows.append(prefix_row(row, mapped_columns, prefix))

        cursor.executemany(sql, rows)
        print(f"Imported {len(rows)} rows into {table_name} (prefix={prefix!r})")


# --- VBN ---
VBN = "VBN_"
AVV = "AVV_"
VBB = "VBB_"
DELFI = "DELFI_"
DE = "de_"
ELRON = "elron_"
KAUGLIINID = "kaugliinid_"
import_gtfs_file("/home/patoll/.config/quickshell/opnv/server/gtfs/kaugliinid/stops.txt", "stops", [
    "stop_id", "stop_code", "stop_name", "stop_desc", "stop_lat", "stop_lon",
    "zone_id", "stop_url", "location_type", "parent_station", "wheelchair_boarding"
], prefix=KAUGLIINID)

import_gtfs_file("/home/patoll/.config/quickshell/opnv/server/gtfs/kaugliinid/routes.txt", "routes", [
    "route_id", "agency_id", "route_short_name", "route_long_name", "route_desc",
    "route_type", "route_url", "route_color", "route_text_color"
], prefix=KAUGLIINID)

import_gtfs_file("/home/patoll/.config/quickshell/opnv/server/gtfs/kaugliinid/trips.txt", "trips", [
    "trip_id", "route_id", "service_id", "trip_headsign", "trip_short_name",
    "direction_id", "block_id", "shape_id", "wheelchair_accessible", "bikes_allowed"
], prefix=KAUGLIINID)

import_gtfs_file("/home/patoll/.config/quickshell/opnv/server/gtfs/kaugliinid/calendar.txt", "calendar", [
    "service_id", "monday", "tuesday", "wednesday", "thursday",
    "friday", "saturday", "sunday", "start_date", "end_date"
], prefix=KAUGLIINID)

import_gtfs_file("/home/patoll/.config/quickshell/opnv/server/gtfs/kaugliinid/calendar_dates.txt", "calendar_dates", [
    "service_id", "date", "exception_type"
], prefix=KAUGLIINID)

cursor.close()
conn.close()
print("GTFS import complete!")