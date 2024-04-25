const { Storage } = require('@google-cloud/storage');
const { PubSub } = require('@google-cloud/pubsub');
const { Firestore } = require('@google-cloud/firestore');
const { BigQuery } = require('@google-cloud/bigquery');
const crypto = require('crypto');

const projectId = 'docai-accelerator';
const databaseId = 'ai-alchemists-db'
const storage = new Storage({ projectId });
const pubsub = new PubSub({ projectId });
const bigquery = new BigQuery({ projectId });
const db = new Firestore({
  projectId: projectId,
  databaseId: databaseId
});

function hashPassword(password) {
  return crypto.createHash('md5').update(password).digest('hex');
}

const createDbCollection = async (collectionName) => {
  try {
    await db.collection(collectionName).doc().set({});
    console.log(`Collection '${collectionName}' created successfully.`);
  } catch (error) {
    console.error('Error creating collection:', error);
  }
};

const registerDbUser = async (username, password) => {
  try {
    const hashedPassword = hashPassword(password);
    const uuid = crypto.randomBytes(16).toString('hex'); // Generate UUID
    const query = `
      INSERT INTO \`docai-accelerator.ai_alchemists_user_table.users\`
      (user_id, password, uuid)
      VALUES ('${username}', '${hashedPassword}', '${uuid}')
    `;
    await bigquery.query(query, {location: "europe-west3"});
    console.log(`User ${username} registered successfully with UUID: ${uuid}`);
    await createDbCollection(uuid);
    return { success: true, uuid };
  } catch (error) {
    console.error('Error registering user:', error);
    return { success: false, error: error.message };
  }
};

const chatHistory = async (uuid) => {
    console.log(uuid);
    // Retrieve messages from Firestore
    const messagesRef = db.collection(uuid).orderBy('timestamp', 'asc');
    const messages = [];
    const querySnapshot = await messagesRef.get();
    querySnapshot.forEach((doc) => {
      const data = doc.data();
      const timestamp = new Date(data.timestamp);
      const hoursMinutes = timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
      const message = { statement: data.statement, timestamp: hoursMinutes };
      messages.push(message);
    });
    return messages;
  };
  
const updateDb = async (message, uuid) => {
  const timestamp = new Date().toLocaleString('en-US', {
    timeZone: 'Europe/Bucharest',
    hour12: false,
  });
  const postMessage = { timestamp: timestamp,
                  statement: message,
  };
  message.timestamp = timestamp;
  await db.collection(uuid).add(postMessage);
  console.log('Message added to Firestore');
};
  
const publishMessage = async (topicId, message) => {
  const dataBuffer = Buffer.from(message);
  try {
    const topic = pubsub.topic(topicId);
    await topic.publish(dataBuffer);
    console.log(`Message published to ${topic.name}`);
  } catch (error) {
    console.error('Error publishing message:', error);
  }
};
  
const fs = require('fs');
const uploadFileToBucket = async (file, bucketName, destinationBlobName) => {
  try {
    const bucket = storage.bucket(bucketName);
    const blob = bucket.file(destinationBlobName);
    const fileContent = fs.readFileSync(file.path);
    await blob.save(fileContent);
    console.log(`File ${file.originalname} uploaded to ${destinationBlobName} in ${bucketName} bucket.`);
  } catch (error) {
    console.error('Error uploading file:', error);
  }
};

const queryBigquery = async(username, password) => {
  const hashedPassword = hashPassword(password);
  console.log(username);
  console.log(password);
  const query = `
      SELECT user_id, uuid
      FROM \`docai-accelerator.ai_alchemists_user_table.users\`
      WHERE user_id = '${username}'
      AND password = '${hashedPassword}'
      LIMIT 1
  `;
  console.log(query);
  // Parameters for the query
  // Run the query
  const [rows] = await bigquery.query(query, {location: "europe-west3"});
  // console.log(rows);
  return rows;
};

module.exports = {
  chatHistory,
  updateDb,
  publishMessage,
  uploadFileToBucket,
  queryBigquery,
  registerDbUser,
};