const { MongoClient } = require("mongodb");

const uri = "mongodb://localhost:27017";
const client = new MongoClient(uri);

async function seed() {
  await client.connect();

  const db = client.db("shuttlebus_system");
  const col = db.collection("stations");

  await col.deleteMany({});

  const stations = [
    {
      id: "station1",
      name: "Station 01 (จุดหอพักลำดวน 2)",
      lat: 20.05896500699539,
      lng: 99.8988796884786,
      lines: ["line1", "line2"],
      waiting: 0,
      status: "LOW",
      isReal: true
    },
    {
      id: "station2",
      name: "Station 02 (จุดพักลำดวน 7 ขาเข้า)",
      lat: 20.057081156842653,
      lng: 99.89702395554524,
      lines: ["line1", "line2"],
      waiting: 5,
      status: "LOW",
      isReal: false
    },
    {
      id: "station3",
      name: "Station 03 (จุด หอพักจีน ขาเข้า)",
      lat: 20.050870176213458,
      lng: 99.8913375758622,
      lines: ["line1", "line2"],
      waiting: 7,
      status: "MEDIUM",
      isReal: false
    },
    {
      id: "station4",
      name: "Station 04 (จุด ศูนย์จีน ขาเข้า)",
      lat: 20.048895164537097,
      lng: 99.89132709650245,
      lines: ["line1", "line2"],
      waiting: 3,
      status: "LOW",
      isReal: false
    },
    {
      id: "station5",
      name: "Station 05 (จุด ลานจอดหอพัก F)",
      lat: 20.048215214947664,
      lng: 99.89322591378016,
      lines: ["line1", "line2"],
      waiting: 10,
      status: "HIGH",
      isReal: false
    },
     {
      id: "station6",
      name: "Station 06 (จุด อาคารโรงอาหาร D1)",
      lat: 20.047237196545165,
      lng: 99.89329478216467,
      lines: ["line1", "line2"],
      waiting: 0,
      status: "LOW",
      isReal: true
    },
     {
      id: "station7",
      name: "Station 07 (จุด สระน้ำวงรี ลานดาว)",
      lat: 20.045606104291842,
      lng: 99.89153621441135,
      lines: ["line1", "line2"],
      waiting: 10,
      status: "HIGH",
      isReal: false
    },
     {
      id: "station8",
      name: "Station 08 (จุด อาคารโรงอาหาร E2 ขาเข้า)",
      lat: 20.04399637202456,
      lng: 99.893402801156,
      lines: ["line1", "line2"],
      waiting: 10,
      status: "HIGH",
      isReal: false
    },
     {
      id: "station9",
      name: "Station 09 (จุด อาคารเรียนรวม C3 C2 และ หอประชุมสมเด็จย่า C4)",
      lat: 20.043895277649657,
      lng: 99.89521575716422,
      lines: ["line1"],
       waiting: 7,
      status: "MEDIUM",
      isReal: false
     },
     {
      id: "station10",
      name: "Station 10 (จุด อาคารเรียนรวม C5 )",
      lat: 20.043346224233225,
      lng: 99.89513551300819,
      lines: ["line1"],
       waiting: 5,
      status: "LOW",
      isReal: false
    },
     {
      id: "station11",
      name: "Station 11 (จุด อาคาร m - square)",
      lat: 20.045780781087203,
      lng: 99.89135359185909,
      lines: ["line1", "line2"],
      waiting: 10,
      status: "HIGH",
      isReal: false
    },
     {
      id: "station12",
      name: "Station 12 (จุด ศูนย์จีน ขาออก)",
      lat: 20.048986374924546,
      lng: 99.89118215098704,
      lines: ["line1", "line2"],
        waiting: 5,
      status: "LOW",
      isReal: false
    },
     {
      id: "station13",
      name: "Station 13 (จุด หอพักจีน ขาออก)",
      lat: 20.05134933875068,
      lng: 99.8914018941547,
      lines: ["line1", "line2"],
      waiting: 0,
      status: "LOW",
      isReal: true
    },
     {
      id: "station14",
      name: "Station 14 (จุด สนามกีฬากลาง)",
      lat: 20.054763275437402,
      lng: 99.89454537873918,
      lines: ["line1", "line2"],
      waiting: 10,
      status: "HIGH",
      isReal: false
    },
     {
      id: "station15",
      name: "Station 15 (จุด หอพักลำดวน 7 ขาออก)",
      lat: 20.056724686542545,
      lng: 99.89712571588397,
      lines: ["line1", "line2"],
        waiting: 7,
      status: "MEDIUM",
      isReal: false
    },
     {
      id: "station16",
      name: "Station 16 (จุด ครัวลำดวน)",
      lat: 20.058276924103307,
      lng:99.89811278167763,
      lines: ["line1", "line2"],
      waiting: 10,
      status: "HIGH",
      isReal: false
    },
    // line 2 (โรงพยาบาลแม่ฟ้าหลวง)
    {
      id: "station17",
      name: "Station 17 (จุด โรงพยาบาลแม่ฟ้าหลวง)",
      lat:  20.041278409327774,
      lng: 99.89430864493072,
      lines: ["line2"],
      waiting: 0,
      status: "LOW",
      isReal: true
    },
  

  ];

  await col.insertMany(stations);

await col.createIndex({ id: 1 }, { unique: true });
await col.createIndex({ lines: 1 });

console.log("✅ Insert stations success");

await client.close();
process.exit();
}

seed();