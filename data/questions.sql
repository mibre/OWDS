Varmast någonsin Ute
select max(temperature) from sensor_data d, sensors s where d.sensor_id = s.one_wire_id and s.name = 'Ute';

Warmest today,  by location
sqlite3 owds.db "select max(temperature) from sensor_data where sensor_id in (select one_wire_id from sensors where location = 'Uterummet') and sensor_data_time > current_date" Klart snabbare!!
sqlite3 owds.db "select max(temperature) from sensor_data d, sensors s where d.sensor_id = s.one_wire_id and s.name = 'Uterummet' and sensor_data_time > current_date" Klart långsammare!!

Sensors in order
sqlite3 data/owds.db "select location from sensors order by bus_order asc"
