const socket = io('', {transports: ['websocket']});

socket.on('connect_error', (error) => {
    console.error('Connection Error:', error);
});

function toggleLoadingScreen() {
    const loadingScreen = document.getElementById('loadingScreen');
    if (window.getComputedStyle(loadingScreen).display === 'flex') {
        loadingScreen.style.display = 'none';
    } else {
        loadingScreen.style.display = 'flex';
    }
}

const dynamicOptions = ['Today', 'Last 7 Days', 'Last Month', 'Last 6 Months', 'Last Year'];
const legendContainer = document.getElementById('legend');
const ctx = document.getElementById('barChart').getContext('2d');

const timeframeText = document.querySelector('.timeframe p');

// Function to update the timeframe text based on the selected option
function updateSelectedTimeframe(option) {
    switch(option) {
        case 'today':
            timeframeText.textContent = 'Data based on today';
            break;
        case '7days':
            timeframeText.textContent = 'Data based on the last 7 days';
            break;
        case 'month':
            timeframeText.textContent = 'Data based on the last month';
            break;
        case '6months':
            timeframeText.textContent = 'Data based on the last 6 months';
            break;
        case 'year':
            timeframeText.textContent = 'Data based on the last year';
            break;
        default:
            timeframeText.textContent = '';
            break;
    }
}

function createLegendItems(keywords, colorScale) {
    while (legendContainer.firstChild) {
        legendContainer.removeChild(legendContainer.firstChild);
    }
    keywords.forEach((keyword, index) => {
        const color = colorScale[index];
        const listItem = document.createElement('li');
        listItem.innerHTML = `<div class="legend-color" style="background-color: ${color};"></div>${keyword}`;
        legendContainer.appendChild(listItem);
    });
}

let barChart = null; // Declare the barChart variable outside the function
function createChart(data){
    if (barChart) {
        barChart.destroy();
    }
    
    // Sort data based on the frequency
    data.sort((a, b) => b.frequency - a.frequency);
    
    // Sort data based on the frequency
    data.sort((a, b) => b.frequency - a.frequency);
    
    const chartData = data.map(item => {
        const keyName = item.keyword ? 'keyword' : 'keywords';
        return {
            [keyName]: item[keyName] || item['keywords'],
            frequency: item.frequency
        };
    });

    const keywords = chartData.map(item => item.keyword || item.keywords);
    const frequencies = chartData.map(item => item.frequency);
    
    // Generate colors using Chroma.js color scale
    const colorScale = chroma.scale(['#4285F4', '#EA4335', '#FBBC05', '#34A853', '#4A90E2', '#F5511D', '#10A674']).mode('lch').colors(keywords.length);
    barChart = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: keywords,
            datasets: [{
                label: '',
                data: frequencies,
                backgroundColor: colorScale,
                borderColor: colorScale,
                borderWidth: 1
            }]
        },
        options: {
            scales: {
                x: {
                    display: false // Hide x-axis labels
                },
                y: {
                    ticks: {
                        beginAtZero: true
                    },
                }
            },
            plugins: {
                legend: {
                    display: false // Hide the legend
                }
            }
        }
    });
    createLegendItems(keywords, colorScale);
}
createChart([]);

let uuidClient;
// Populate the dropdown with dynamic options
const timeframeSelect = document.getElementById('timeframeSelect');
dynamicOptions.forEach(option => {
    const optionElement = document.createElement('option');
    optionElement.value = option.toLowerCase().replace(/\s/g, '').replace('last','');
    optionElement.textContent = option;
    timeframeSelect.appendChild(optionElement);
});

generateBtn.addEventListener('click', async () => {
    const selectedOption = timeframeSelect.value;
    console.log('Selected option:', selectedOption);
    const formData = {
        "timeframe": selectedOption
    };
    try {
        const response = await fetch('/generatestats', {
            method: 'POST',
            body: JSON.stringify(formData), // Ensure formData is stringified
            headers: {
                'Content-Type': 'application/json' // Set Content-Type header
            }
        });
        toggleLoadingScreen();
        const data = await response.json();
        uuidClient = data.postMessage.uuid;
        console.log(data);
    } catch (error) {
        console.error('Error:', error);
        // Handle error (e.g., display error message to user)
    }
});

// Event listener for WebSocket messages
socket.on('stats', function(message) {
    if (uuidClient === message.uuid) {
        toggleLoadingScreen();
        // Update the UI with the received message
        createChart(JSON.parse(message.response));
        // createChart(message);
        updateSelectedTimeframe(timeframeSelect.value);
    }
});