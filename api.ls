ews = require('ews-javascript-api')

exports.get_room_availability = (netid, password, room-netids, date-string, cb) ->
  if netid.indexOf("@") != -1
    return Promise.reject message: "Invalid netid"

  exch = new ews.ExchangeService ews.ExchangeVersion.Exchange2013
  exch.Credentials = new ews.ExchangeCredentials(netid + "@cornell.edu", password)
  exch.Url = new ews.Uri "https://outlook.office365.com/Ews/Exchange.asmx"

  # Build and verify attendee list
  for id in room-netids
    if id.index-of("@") != -1
      return Promise.reject message: "Invalid room ID"
  attendee = [new ews.AttendeeInfo(id + "@cornell.edu") for id in room-netids]

  # Build time window
  day = ews.DateTime.Parse date-string
  timeWindow = new ews.TimeWindow(
    new ews.DateTime(day.TotalMilliSeconds - ews.TimeSpan.FromHours(24).duration.asMilliseconds()),
    new ews.DateTime(day.TotalMilliSeconds + ews.TimeSpan.FromHours(24).duration.asMilliseconds()),
  )

  cal <- exch.GetUserAvailability(
      attendee, timeWindow, ews.AvailabilityData.FreeBusy
  ).then
  make-attendee-response = (res) ->
   error-message: res.error-message
   events: [ \
     start: ev.start-time.Format!, \
     end: ev.end-time.Format!, \
     busy: ev.free-busy-status \
     for ev in res.calendar-events]
  {[room-netids[i], make-attendee-response res] \
    for res, i in cal.attendeesAvailability.responses ? []}
