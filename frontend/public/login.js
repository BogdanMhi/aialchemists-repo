const outputMessage = document.getElementById('output-message');

document.getElementById('loginForm').addEventListener('submit', async function(event) {
    event.preventDefault(); // Prevent the form from submitting

    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    // Check if username and password are not empty
    if (username.trim() === '' || password.trim() === '') {
        // Display error message if fields are empty
        const errorMessage = document.getElementById('error-message');
        errorMessage.textContent = 'Please enter both username and password.';
        errorMessage.style.display = 'block';
        return; // Stop further execution
    }

    // If fields are not empty, proceed with form submission
    const message = {
        username: username,
        password: password
    };

    const response = await fetch('/login', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(message)
    });

    if (!response.ok) {
        // Handle errors or display error message if upload fails
        outputMessage.textContent = 'You have entered an incorrect username or password. Please try again.';
        outputMessage.style.display = 'block';
        outputMessage.classList.remove('success-message');
        outputMessage.classList.add('error-message');
    } else {
        window.location.href = '/';
        // Reset form fields if upload is successful
        document.getElementById('username').value = '';
        document.getElementById('password').value = ''; // Clear file input
        // Hide error message
        document.getElementById('error-message').style.display = 'none';
    }
});

// Send a POST request to the /register endpoint with the new user data
document.getElementById('registerButton').addEventListener('click', async function(event) {
    event.preventDefault(); // Prevent the default form submission behavior

    const username = document.getElementById('username').value;
    const password = document.getElementById('password').value;

    // Check if username and password are not empty
    if (username.trim() === '' || password.trim() === '') {
        outputMessage.textContent = 'Please enter both username and password.';
        outputMessage.style.display = 'block';
        outputMessage.classList.remove('success-message');
        outputMessage.classList.add('error-message');
        return; // Stop further execution if fields are empty
    }

    const newUser = {
        username: username,
        password: password
    };

    // Send a POST request to the /register endpoint with the new user data
    const response = await fetch('/register', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(newUser)
    });

    if (!response.ok) {
        // Display error message if registration fails
        outputMessage.textContent = 'User already registered!';
        outputMessage.classList.remove('success-message');
        outputMessage.classList.add('error-message');
        outputMessage.style.display = 'block';
    } else {
        // Display success message and clear the form
        outputMessage.textContent = 'Registration successful! Please log in.';
        outputMessage.classList.remove('error-message');
        outputMessage.classList.add('success-message');
        outputMessage.style.display = 'block';

        document.getElementById('username').value = '';
        document.getElementById('password').value = '';
    }
});
