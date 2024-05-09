const multer = require('multer');
const express = require('express');

const { 
  chatHistory, 
  updateDb, 
  publishMessage, 
  uploadFileToBucket, 
  queryBigquery, 
  registerDbUser,
  cleanUserConversation } = require('./utils');



const app = express();
const session = require('express-session');
app.use(express.json());
app.use(express.static(__dirname + '/public'));
app.use(session({
  secret: 'your_secret_key', // Choose a strong secret for session encoding
  resave: false,
  saveUninitialized: true,
  cookie: { secure: 'auto' } // secure: true in production with HTTPS
}));

app.set('view engine', 'ejs');
app.set('views', 'public/');

// Initialize Socket.io
const server = require('http').Server(app);
const io = require('socket.io')(server);

// Socket.io connection event
io.on('connection', (socket) => {
  console.log('A client connected');
});

app.get('/login', (req, res) => {
  res.render('login');
});

// Middleware to check if the user is authenticated
function isAuthenticated(req, res, next) {
  if (req.session && req.session.user) {
      return next();
  } else {
      console.log("Unauthenticated request");
      res.redirect('/login');
  }
}

app.get('/newconversation', isAuthenticated, async (req, res) => {
  try {
      cleanUserConversation(req.session.user.uuid);
      console.log("I'm here!")
      res.status(200).json({ success: true});
  } catch (error) {
      // Handle any errors that occur during the process of starting a new conversation
      console.error('Error:', error);
      res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
});

app.post('/login', async (req, res) => {
  const { username, password } = req.body;
  try {
    rows = await queryBigquery(username, password);
    // const user = users.find(u => u.username === username && u.password === password);
    console.log(rows);
    console.log(rows.length);
    if (rows.length > 0 ) {
        console.log('Login Succesful');
        req.session.user = rows[0];  // Set the user in the session
        // res.redirect('/');  // Redirect to the root URL after successful login
        res.status(200).json({ success: true, redirectUrl: '/' });
    } else {
        console.log('Invalid username or password');
        res.status(401).json({ success: false, message: 'Invalid username or password' });
    }
    } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
});

app.post('/register', async (req, res) => {
  const { username, password } = req.body;
  try {
    rows = await queryBigquery(username);
    if (rows.length > 0 ) {
      res.status(401).json({ success: false, message: 'User already registered' });
    } else {
        const result = await registerDbUser(username, password);
        if (result.success) {
          res.status(201).json({ message: 'User registered successfully', userId: result.uuid });
        } else {
          res.status(500).json({ message: 'Registration failed', error: result.error });
        }
      }
  } catch (error) {
    console.error('Error in registration process:', error);
    res.status(500).json({ message: 'Internal server error', error: error.message });
    }
});

// Serve frontend
app.get('/', isAuthenticated, async (req, res) => {
  try {
    const messages = await chatHistory(req.session.user.uuid);
    console.log(messages);
    res.render('index.ejs', { messages });
  } catch (error) {
    console.error('Error retrieving chat history:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Handle logout request
app.get('/logout', (req, res) => {
  req.session.destroy();
  res.redirect('/login');
});

// Configure multer for handling file uploads
const upload = multer({ dest: 'uploads/' });
// Handle file uploads
app.post('/upload', isAuthenticated, upload.single('file'), async (req, res) => {
  try {
    const textInput = req.body.textInput;
    console.log(req.session.user.uuid);
    const file = req.file; // Multer parses the file and stores the metadata in req.file
    const postMessage = {uuid: req.session.user.uuid};

    if (!textInput && !file) {
      return res.status(400).json({ message: 'No text input or file provided' });
    }

    if (textInput && !file) {
      console.log(`Text input: ${textInput}`);
      postMessage.statement = textInput;
      await updateDb(postMessage.statement, postMessage.uuid);
      await publishMessage('format_classifier_trigger', JSON.stringify(postMessage));
      res.json({ message: 'Upload successful', data: postMessage });
    }
    else if (file) {
      console.log(`Processing file: ${file.originalname}`);
      await uploadFileToBucket(file, "ingestion_data_placeholder", file.originalname);
      postMessage.file_path = file.originalname;
      if (textInput) {
          postMessage.statement = textInput; // Ensure postMessage.statement is set only if textInput is provided
          await updateDb(postMessage.statement, postMessage.uuid)
      }
      await publishMessage('format_classifier_trigger', JSON.stringify(postMessage));
      res.json({ message: 'Upload successful', data: postMessage });
    }
  } catch (error) {
    console.error('Error during upload:', error);
    res.status(500).json({ message: 'Upload failed', error: error.message });
  }
});

// Handle model response
app.post('/model', async (req, res) => {
  try {
    const response = req.body.response;
    const uuid = req.body.uuid;
    console.log(`Response model: ${response}`);
    await updateDb(response, uuid, model_output=true);
    // await publishMessage('format_classifier_trigger', JSON.stringify(postMessage));
    io.emit('notification', response);
    res.status(200).json({ message: 'Notification sent successfully' });
  } catch (error) {
    console.error('Error sending notification:', error);
    res.status(500).json({ message: 'Failed to send notification', error: error.message });
  }
});

module.exports = server;
