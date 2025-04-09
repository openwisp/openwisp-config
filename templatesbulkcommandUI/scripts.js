// Dynamically update the fields based on selected target scope
document.getElementById('scope').addEventListener('change', function() {
    const scope = this.value;
    const dynamicFields = document.getElementById('dynamic-fields');
    
    // Clear previous dynamic fields
    dynamicFields.innerHTML = '';

    // Show different fields based on the selected scope
    switch(scope) {
        case 'organization':
            dynamicFields.innerHTML = `
                <label for="organization">Select Organization</label>
                <input type="text" id="organization" class="input-field" placeholder="Enter organization name" />
            `;
            break;
        case 'device-group':
            dynamicFields.innerHTML = `
                <label for="device-group">Select Device Group</label>
                <input type="text" id="device-group" class="input-field" placeholder="Enter device group" />
            `;
            break;
        case 'geolocation':
            dynamicFields.innerHTML = `
                <label for="location">Select Location</label>
                <input type="text" id="location" class="input-field" placeholder="Enter location" />
            `;
            break;
        case 'specific-devices':
            dynamicFields.innerHTML = `
                <label for="devices">Enter Device IDs</label>
                <input type="text" id="devices" class="input-field" placeholder="Enter device IDs (comma-separated)" />
            `;
            break;
        default:
            dynamicFields.innerHTML = '';
    }
});

// Handle form submission (alert if any field is empty)
function submitForm(event) {
    // Prevent default form submission
    event.preventDefault();

    // Get the command value and trim it
    const command = document.getElementById('command').value.trim();
    const scope = document.getElementById('scope').value;

    // Check if the command is empty
    if (!command) {
        alert('Please enter a command.');
        return;
    }

    let dynamicFieldValid = true;

    // Validate dynamic fields based on the scope selected
    switch(scope) {
        case 'organization':
            const organization = document.getElementById('organization').value.trim();
            if (!organization) {
                dynamicFieldValid = false;
                alert('Please enter an organization.');
            }
            break;
        case 'device-group':
            const deviceGroup = document.getElementById('device-group').value.trim();
            if (!deviceGroup) {
                dynamicFieldValid = false;
                alert('Please enter a device group.');
            }
            break;
        case 'geolocation':
            const location = document.getElementById('location').value.trim();
            if (!location) {
                dynamicFieldValid = false;
                alert('Please enter a location.');
            }
            break;
        case 'specific-devices':
            const devices = document.getElementById('devices').value.trim();
            if (!devices) {
                dynamicFieldValid = false;
                alert('Please enter device IDs.');
            }
            break;
        default:
            break;
    }

    // If any dynamic field is empty, don't submit
    if (!dynamicFieldValid) {
        return;
    }

    // If all fields are valid, show a success message
    alert('Command Submitted: ' + command);

    // Reset the form or show a success message
    document.getElementById('command').value = '';
    document.getElementById('dynamic-fields').innerHTML = '';
}

// Trigger default selection (All Devices)
document.getElementById('scope').dispatchEvent(new Event('change'));
