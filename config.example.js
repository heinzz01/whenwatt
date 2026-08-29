// Copy this file to config.js and fill in your own values.
// config.js is gitignored - it must never be committed.
//
// Where to get them: ClickHouse Cloud -> saved query "hourly_curve"
// -> Share -> API Endpoint. The endpoint id sits between /run/ and "?"
// in the curl command it shows you.
//
// SECURITY: these values reach the browser and are readable by anyone
// who opens the deployed site. Only acceptable when the endpoint uses a
// READ ONLY database role, the API key has the Member organisation role
// (never Admin), and CORS is limited to your own domain.

window.WHENWATT_CONFIG = {
  endpointId: "",
  keyId:      "",
  keySecret:  "",
  country:    "de"
};
