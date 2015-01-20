(* Create an iCal event using Applescript *)

(*
set calTitle to "Birthdays"
set eventTitle to "John Smith's Birthday"
set eventDay to 13
set eventMonth to September
set eventMonthNum to 9
set eventYear to 2002
*)

tell application "iCal"
	set bDate to current date
	set time of bDate to 32400 -- seconds, = 9 hours = 9am, starting time of non-all-day events (if appropriate)
	set year of bDate to eventYear
	set month of bDate to eventMonth
	set day of bDate to eventDay
        set allday to true -- whether to make "all-day" events
	set myevent to make new event at the end of events of (item 1 of (calendars whose title is calTitle)) with properties {start date:bDate, end date:bDate + 1 * hours, allday event: allday, summary:eventTitle, recurrence:("FREQ=YEARLY;INTERVAL=1;BYMONTH=" & eventMonthNum)}
end tell
