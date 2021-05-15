set @totalDistinctRoomsUsedIn2013 = (SELECT
	count(*)
FROM
	room
WHERE
	RoomNumber NOT in( SELECT DISTINCT
			(room)
			FROM stay
		WHERE
			YEAR(StayStart) = '2013'));

SET @totalAvailableRooms = (
SELECT
	count(*) AS totalRooms
	FROM
		room
	WHERE
		Unavailable = 0);

select 'no' as answer 
where @totalDistinctRoomsUsedIn2013= @totalAvailableRooms
UNION
select 'yes' as answer 
where @totalDistinctRoomsUsedIn2013 <> @totalAvailableRooms 
