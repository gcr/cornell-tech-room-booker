var ews = require('ews-javascript-api');
//create ExchangeService object

exports.get_room_availability = function(netid, password, room_netids, cb) {
  if (netid.indexOf("@") != -1) {
    return Promise.reject("Invalid netid");
  }

  var exch = new ews.ExchangeService(ews.ExchangeVersion.Exchange2013);
  exch.Credentials = new ews.ExchangeCredentials(netid + "@cornell.edu", password);
  exch.Url = new ews.Uri("https://outlook.office365.com/Ews/Exchange.asmx");
  var attendee = [];
  for (var i=0; i<room_netids.length; i++) {
    if (room_netids[i].indexOf("@") != -1) {
      return Promise.reject("Invalid netid");
    }
    attendee.push(new ews.AttendeeInfo(room_netids[i] + "@cornell.edu"));
  }
  var timeWindow = new ews.TimeWindow(
    new ews.DateTime(ews.DateTime.Now.TotalMilliSeconds - ews.TimeSpan.FromHours(48).duration.asMilliseconds()),
    new ews.DateTime(ews.DateTime.Now.TotalMilliSeconds + ews.TimeSpan.FromHours(48).duration.asMilliseconds())
  );
  return exch.GetUserAvailability(attendee, timeWindow, ews.AvailabilityData.FreeBusy)
    .then(function (availabilityResponse) {
            //do what you want with user availability
            return availabilityResponse;
          });
};
