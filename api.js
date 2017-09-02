// Generated by LiveScript 1.4.0
(function(){
  var ews;
  ews = require('ews-javascript-api');
  exports.get_room_availability = function(netid, password, roomNetids, cb){
    var exch, i$, len$, id, attendee, res$, timeWindow;
    if (netid.indexOf("@") !== -1) {
      return Promise.reject({
        message: "Invalid netid"
      });
    }
    exch = new ews.ExchangeService(ews.ExchangeVersion.Exchange2013);
    exch.Credentials = new ews.ExchangeCredentials(netid + "@cornell.edu", password);
    exch.Url = new ews.Uri("https://outlook.office365.com/Ews/Exchange.asmx");
    for (i$ = 0, len$ = roomNetids.length; i$ < len$; ++i$) {
      id = roomNetids[i$];
      if (id.indexOf("@") !== -1) {
        return Promise.reject({
          message: "Invalid room ID"
        });
      }
    }
    res$ = [];
    for (i$ = 0, len$ = roomNetids.length; i$ < len$; ++i$) {
      id = roomNetids[i$];
      res$.push(new ews.AttendeeInfo(id + "@cornell.edu"));
    }
    attendee = res$;
    timeWindow = new ews.TimeWindow(new ews.DateTime(ews.DateTime.Now.TotalMilliSeconds - ews.TimeSpan.FromHours(24).duration.asMilliseconds()), new ews.DateTime(ews.DateTime.Now.TotalMilliSeconds + ews.TimeSpan.FromHours(24).duration.asMilliseconds()));
    return exch.GetUserAvailability(attendee, timeWindow, ews.AvailabilityData.FreeBusy).then(function(cal){
      var makeAttendeeResponse, i$, ref$, ref1$, len$, i, res, resultObj$ = {};
      makeAttendeeResponse = function(res){
        var ev;
        return {
          errorMessage: res.errorMessage,
          events: (function(){
            var i$, ref$, len$, results$ = [];
            for (i$ = 0, len$ = (ref$ = res.calendarEvents).length; i$ < len$; ++i$) {
              ev = ref$[i$];
              results$.push({
                start: ev.startTime.Format(),
                end: ev.endTime.Format(),
                busy: ev.freeBusyStatus
              });
            }
            return results$;
          }())
        };
      };
      for (i$ = 0, len$ = (ref$ = (ref1$ = cal.attendeesAvailability.responses) != null
        ? ref1$
        : []).length; i$ < len$; ++i$) {
        i = i$;
        res = ref$[i$];
        resultObj$[roomNetids[i]] = makeAttendeeResponse(res);
      }
      return resultObj$;
    });
  };
}).call(this);
