import moment from "moment";

export function formatSecond(second) {
  const days = Math.floor(second / 86400);
  const hours = Math.floor((second % 86400) / 3600);
  const minutes = Math.floor(((second % 86400) % 3600) / 60);
  const seconds = Math.floor(((second % 86400) % 3600) % 60);

  let formatedTime = `${days} ${days > 1 ? "days" : "day"}`;
  if (days <= 0) {
    formatedTime = `${hours} ${hours > 1 ? "hours" : "hour"}`;
  } else if (hours <= 0 && days <= 0) {
    formatedTime = `${minutes}m`;
  } else if (hours <= 0 && days <= 0 && minutes <= 0) {
    formatedTime = `${seconds}s`;
  } else if (seconds <= 0 && minutes <= 0 && hours <= 0 && days <= 0) {
    formatedTime = `Withdraw`;
  }
  return formatedTime;
}

export function timeLeftInSeconds(typeStaking, since) {
  let startDate = moment.unix(since).toDate();
  let endDate;
  switch (typeStaking) {
    case "silver":
      endDate = moment(startDate).add(3, "M");
      break;
    case "gold":
      endDate = moment(startDate).add(6, "M");
      break;
    case "diamond":
      endDate = moment(startDate).add(9, "M");
      break;
    default:
      endDate = moment(startDate).add(3, "M");
      break;
  }
  const timeToWait = endDate.diff(startDate) / 1000;
  const timePastSince = moment().valueOf() / 1000 - since;
  if ((timeToWait - Math.round(timePastSince)) <= 0) {
    return 0;
  } else {
    return timeToWait - Math.round(timePastSince);
  }
}

// 127236791 into 127,236,791
export function formatNumber(number) {
  return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}
