select
    t.id,
    t.scheduled_departure_utc,
    t.status
from trips t
where t.route_id = :route_id
  and t.scheduled_departure_utc >= :after_utc
order by t.scheduled_departure_utc
limit 20;

select
    rs.stop_sequence,
    s.id,
    s.name
from route_stops rs
join stops s
    on s.id = rs.stop_id
where rs.route_id = :route_id
order by rs.stop_sequence;

select
    r.id,
    r.short_name,
    count(t.id) as trip_count
from routes r
left join trips t
    on t.route_id = r.id
   and t.service_date = :service_date
group by r.id, r.short_name
order by r.short_name;
