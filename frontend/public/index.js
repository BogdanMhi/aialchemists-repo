// Connect to the WebSocket server
// const socket = io();
//const socket = io('wss://hello-world-app-adwexujega-ey.a.run.app/socket.io/?EIO=4&transport=websocket', {transports: ['websocket', 'polling']});
// Connect to the WebSocket server
const socket = io('', {transports: ['websocket']});

socket.on('connect_error', (error) => {
    console.error('Connection Error:', error);
});


const options = {
    timeZone: 'Europe/Bucharest',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  };

// Drag and drop functionality
const dragDropBox = document.getElementById('drag-drop-box');
const fileInfoText = document.getElementById('fileInfoText');
const removeFileButton = document.getElementById('removeFileButton');
const newConversationButton = document.getElementById('newConversationButton');
const fileInput = document.getElementById('fileInput');
const fileSelectButton = document.getElementById('fileSelectButton');
const messageList = document.getElementById('messageList');
const alertMessage = document.getElementById('alertMessage');
const exposeStatisticsButton = document.getElementById('exposeStatisticsButton');


// Function to hide file input and select file button
function hideFileInput() {
    fileInput.disabled = true; // Disable file input
    fileSelectButton.style.display = 'none'; // Hide select file button
}

// Function to handle dropped or selected files
function handleFiles(files) {
    // Handle the dropped or selected files here (e.g., upload to server)
    console.log('File:', files[0]);
}

// Function to show file input and select file button
function showFileInput() {
    fileInput.disabled = false; // Enable file input
    fileSelectButton.style.display = 'inline-block'; // Show select file button
}

function resetFileInput() {
    fileInput.disabled = true; // Enable file input
    fileInput.value = ''; // Clear selected file
    fileInfoText.textContent = 'Drag and Drop Files Here'; // Reset file info text
    removeFileButton.style.display = 'none'; // Hide remove file button
    // Show file input and select file button
    showFileInput();
    // Reset fileUploaded flag to false if needed
    fileUploaded = false; // If fileUploaded is a global variable, uncomment this line
}


function toggleLoadingScreen() {
    const loadingScreen = document.getElementById('loadingScreen');
    if (window.getComputedStyle(loadingScreen).display === 'flex') {
        loadingScreen.style.display = 'none';
    } else {
        loadingScreen.style.display = 'flex';
    }
}

// Event listener for WebSocket messages
socket.on('notification', function(message) {
    // Update the UI with the received message
    toggleLoadingScreen();
    resetFileInput();
    
    const newItem = document.createElement('li');
    const timestamp = new Date().toLocaleTimeString('en-US', options);
    newItem.textContent = `${timestamp} - ${message}`;
    messageList.appendChild(newItem);
});

let fileUploaded = false; // Flag to track if a file is uploaded
document.getElementById('uploadForm').addEventListener('submit', async function(event) {
    event.preventDefault(); // Prevent form submission
    const textInput = document.getElementById('textInput').value.trim(); // Trim whitespace from input
    const files = document.getElementById('fileInput').files; // Get selected files
    const timestamp = new Date().toLocaleTimeString('en-US', options);
    // Clear the text input field
    document.getElementById('textInput').value = '';

    // Add the entered text to the list
    if (textInput) {
        alertMessage.style.display = 'none';
        const listItem = document.createElement('li');
        listItem.textContent = `${timestamp} - ${textInput}`;
        messageList.appendChild(listItem);
    }
    else {
        // Display a message if textInput is empty
        console.log("No text input provided.");
        alertMessage.style.display = 'block';
        // You can add code here to display a message to the user if needed
        return; // Exit the function early since there's nothing else to do
    }

    // Upload files to Google Cloud Storage if a file is selected
    console.log(files.length);
    if (files.length === 1) {
        try {
            const formData = new FormData();
            formData.append('textInput', textInput);
            formData.append('file', files[0]); // Append only the first file

            toggleLoadingScreen();
            // Send a POST request with the form data
            const response = await fetch('/upload', {
                method: 'POST',
                body: formData
            });
            const data = await response.json();
            console.log(data);

            // Hide file input and select file button after successful upload
            hideFileInput();
            fileUploaded = true; // Set fileUploaded flag to true
        } catch (error) {
            console.error('Error:', error);
            toggleLoadingScreen();
        }
    } else {
        console.log("Only text scenario");
        // Handle the case where no file is selected
        // Perform a POST request with the text input
        try {
            const message = {
                textInput: textInput,
            };
            
            // Convert the data object to a JSON string
            const jsonData = JSON.stringify(message);
            toggleLoadingScreen();
            // Send a POST request with the JSON data
            const response = await fetch('/upload', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: jsonData
            });
            const data = await response.json();
            console.log(data);
            
        } catch (error) {
            console.error('Error:', error);
            toggleLoadingScreen();
        }
    }

    // Handle text input (with or without file upload)
    // Add your code to handle text input here, such as printing it or processing it in some way
    console.log('Text Input:', textInput);
});

dragDropBox.addEventListener('dragover', (event) => {
    event.preventDefault();
    dragDropBox.classList.add('dragover');
});

dragDropBox.addEventListener('dragleave', () => {
    dragDropBox.classList.remove('dragover');
});

dragDropBox.addEventListener('drop', (event) => {
    event.preventDefault();
    dragDropBox.classList.remove('dragover');

    const files = event.dataTransfer.files;

    // Check if more than one file is dropped
    if (files.length !== 1) {
        alert('Please drop only one file.'); // Display alert message
        return; // Stop processing
    }

    handleFiles(files);

    // Show drop message
    fileInfoText.textContent = `File: ${files[0].name}`;
    removeFileButton.style.display = 'inline-block'; // Display remove file button

    // Hide file input and select file button
    hideFileInput();
});

newConversationButton.addEventListener('click', async () => {
    try {
        const response = await fetch('/newconversation', {
            method: 'GET'
        });
        if (!response.ok) {
            console.error('Request failed with status:', response.status);
            return; // Stop further execution
        }
        while (messageList.firstChild) {
            messageList.removeChild(messageList.firstChild);
        }
        const data = await response.json();
        console.log(data);
    } catch (error) {
        console.error('Error:', error);
    }
});

exposeStatisticsButton.addEventListener('click', async () => {
    try {
        const response = await fetch('/statistics', {
            method: 'GET'
        });
        if (!response.ok) {
            console.error('Request failed with status:', response.status);
            return; // Stop further execution
        }
        window.location.href = '/statistics';
        console.log(data);
    } catch (error) {
        console.error('Error:', error);
    }
});

// Button to remove file
removeFileButton.addEventListener('click', () => {
    resetFileInput();
});

// Button to select files
document.getElementById('fileSelectButton').addEventListener('click', () => {
    fileInput.click();
});

// Button to remove file
removeFileButton.addEventListener('click', () => {
    resetFileInput();
});

// File input change event listener
fileInput.addEventListener('change', () => {
    const files = fileInput.files;

    // Check if more than one file is selected
    if (files.length !== 1) {
        alert('Please select only one file.'); // Display alert message
        return; // Stop processing
    }

    handleFiles(files);

    // Show file info text
    fileInfoText.textContent = `File: ${files[0].name}`;
    removeFileButton.style.display = 'inline-block'; // Display remove file button

    // Hide file input and select file button
    hideFileInput();
});