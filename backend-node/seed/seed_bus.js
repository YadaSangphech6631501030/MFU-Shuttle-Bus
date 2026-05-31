const { MongoClient } = require("mongodb");

const uri = "mongodb://127.0.0.1:27017";
const client = new MongoClient(uri);

const buses = [
  { busNumber: "1", 
    line: "1", 
    currentStationIndex: 0,
     status: "STOPPED", 
    },
  { busNumber: "2", 
    line: "1", 
    currentStationIndex: 2, 
    status: "RUNNING", 
   },
  { busNumber: "3",
     line: "1", 
     currentStationIndex: 4, 
     status: "ARRIVING", 
     },

  { busNumber: "4", 
    line: "2", currentStationIndex: 1, 
    status: "RUNNING", 
   },
  { busNumber: "5",
     line: "2", 
     currentStationIndex: 3,
      status: "STOPPED", 
    },
  { busNumber: "6", 
    line: "2", 
    currentStationIndex: 5,
    status: "ARRIVING",
    }
];

const seedBus = async () => {
  try {
    await client.connect();
    console.log("✅ Connected to MongoDB");

    const db = client.db("shuttlebus_system");
    const collection = db.collection("buses"); 

    // delete existing data
    await collection.deleteMany({});

    // add new data
    await collection.insertMany(buses);

    console.log("✅ Insert Seed Bus Data successful");
  } catch (err) {
    console.error("❌ Error:", err);
  } finally {
    await client.close();
  }
};

seedBus();