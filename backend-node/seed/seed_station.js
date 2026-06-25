const { MongoClient } = require("mongodb");

const uri = "mongodb://localhost:27017";
const client = new MongoClient(uri);

const stationSeeds = [
  { id: "station01", name: "Lamduan Dormitory 2", nameTH: "", lat: 20.058752, lng: 99.898396, lines: ["line1"], waiting: 10, status: "HIGH", cameraUrl: "" },
  { id: "station02", name: "Lamduan Dormitory 7 (Outbound)", nameTH: "", lat: 20.057039, lng: 99.89693, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station03", name: "Staff Housing Junction", nameTH: "", lat: 20.054683, lng: 99.894515, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station04", name: "D2 Museum Building", nameTH: "", lat: 20.052544, lng: 99.892316, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station05", name: "Chinese Dormitory (Inbound)", nameTH: "", lat: 20.050817, lng: 99.89122, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station06", name: "Chinese Center (Inbound)", nameTH: "", lat: 20.049137, lng: 99.89125, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station07", name: "F Parking Lot", nameTH: "", lat: 20.048193, lng: 99.893221, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station08", name: "D1 Building", nameTH: "", lat: 20.047265, lng: 99.893146, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "rtsp://mfustream:mediamfu2025@172.30.36.122:554/LiveMedia/ch1/Media1/trackID=1", detectionRoi: [] },
  { id: "station09", name: "Oval Pond", nameTH: "", lat: 20.045503, lng: 99.891442, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station10", name: "E2 Building (Inbound)", nameTH: "", lat: 20.043881, lng: 99.893486, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station11", name: "C4 Auditorium", nameTH: "", lat: 20.04392, lng: 99.894909, lines: ["line1"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station12", name: "C5 Building", nameTH: "", lat: 20.043311, lng: 99.895297, lines: ["line1"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station13", name: "E2 Building (Outbound)", nameTH: "", lat: 20.043846, lng: 99.893475, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station14", name: "M-Square Building", nameTH: "", lat: 20.045659, lng: 99.891332, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station15", name: "Chinese Center (Outbound)", nameTH: "", lat: 20.049391, lng: 99.891113, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station16", name: "Chinese Dormitory (Outbound)", nameTH: "", lat: 20.05083, lng: 99.891157, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station17", name: "Lamduan Center", nameTH: "", lat: 20.05269, lng: 99.892342, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station18", name: "Swimming Pool Entrance", nameTH: "", lat: 20.054732, lng: 99.89448, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station19", name: "Lamduan Dormitory 7 (Inbound)", nameTH: "", lat: 20.056898, lng: 99.897119, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station20", name: "Lamduan Food Court", nameTH: "", lat: 20.058064, lng: 99.897875, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station21", name: "Minnimart Lamduan", nameTH: "", lat: 20.058967, lng: 99.899517, lines: ["line1", "line2"], waiting: 0, status: "LOW", cameraUrl: "" },
  { id: "station22", name: "MFU Medical Center", nameTH: "", lat: 20.041244, lng: 99.894427, lines: ["line2"], waiting: 0, status: "LOW", cameraUrl: "" },
];

async function seed() {
  await client.connect();

  const db = client.db("shuttlebus_system");
  const col = db.collection("stations");

  await col.deleteMany({});

  await col.insertMany(stationSeeds);

  await col.createIndex({ id: 1 }, { unique: true });
  await col.createIndex({ lines: 1 });

  console.log("Insert stations success");

  await client.close();
  process.exit();
}

seed();
