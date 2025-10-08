<?php
// Start session if not already started
if (session_status() == PHP_SESSION_NONE) {
    session_start();
}

// Check authentication
if (!isset($_SESSION['SESS_MEMBER_ID']) || (trim($_SESSION['SESS_MEMBER_ID']) == '')) {
    header("location: index.php");
    exit();
}

// Database connection
include 'Connections/coop.php';

$pageTitle = 'API Data Upload - OOUTH COOP';
include 'includes/header.php';

// Load API client
require_once('classes/OOUTHSalaryAPIClient.php');
?>

<div class="max-w-7xl mx-auto">
    <!-- Page Header -->
    <div class="bg-gradient-to-r from-purple-600 to-indigo-600 rounded-xl shadow-lg p-6 mb-8 text-white">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold mb-2">
                    <i class="fas fa-cloud-download-alt mr-3"></i>API Data Upload
                </h1>
                <p class="text-purple-100">Fetch and import data from OOUTH Salary API</p>
            </div>
            <div class="bg-white/20 backdrop-blur-sm p-4 rounded-lg">
                <i class="fas fa-exchange-alt text-3xl"></i>
            </div>
        </div>
    </div>

    <!-- API Status Card -->
    <div id="apiStatusCard" class="bg-white rounded-xl shadow-lg p-6 mb-6 hidden">
        <div class="flex items-center justify-between">
            <div class="flex items-center">
                <div id="statusIndicator" class="w-3 h-3 rounded-full mr-3"></div>
                <div>
                    <p class="text-sm text-gray-600">API Connection Status</p>
                    <p id="statusText" class="text-lg font-semibold"></p>
                </div>
            </div>
            <div class="text-right">
                <p class="text-sm text-gray-600">Resource Access</p>
                <p class="text-lg font-semibold text-indigo-600"><?php echo OOUTH_RESOURCE_NAME; ?></p>
            </div>
        </div>
    </div>

    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <!-- Left Column: Controls -->
        <div class="lg:col-span-1">
            <div class="bg-white rounded-xl shadow-lg p-6 sticky top-4">
                <h2 class="text-xl font-bold text-gray-800 mb-4">
                    <i class="fas fa-sliders-h mr-2"></i>Controls
                </h2>

                <!-- Period Selection -->
                <div class="mb-6">
                    <label class="block text-sm font-medium text-gray-700 mb-2">
                        <i class="fas fa-calendar-alt mr-2"></i>Select Period
                    </label>
                    <select id="apiPeriodSelect"
                        class="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-500 focus:border-transparent">
                        <option value="">Loading periods...</option>
                    </select>
                    <p class="text-xs text-gray-500 mt-2">
                        <i class="fas fa-info-circle mr-1"></i>Select a period to fetch data
                    </p>
                </div>

                <!-- Action Buttons -->
                <div class="space-y-3">
                    <button id="fetchDataBtn" disabled
                        class="w-full px-4 py-3 bg-indigo-600 hover:bg-indigo-700 text-white rounded-lg transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed">
                        <i class="fas fa-download mr-2"></i>Fetch Data from API
                    </button>

                    <button id="uploadDataBtn" disabled
                        class="w-full px-4 py-3 bg-green-600 hover:bg-green-700 text-white rounded-lg transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed">
                        <i class="fas fa-upload mr-2"></i>Upload to Database
                    </button>

                    <button id="clearDataBtn" disabled
                        class="w-full px-4 py-3 bg-gray-500 hover:bg-gray-600 text-white rounded-lg transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed">
                        <i class="fas fa-trash-alt mr-2"></i>Clear Data
                    </button>
                </div>

                <!-- Stats Card -->
                <div id="statsCard" class="mt-6 bg-gradient-to-br from-indigo-50 to-purple-50 rounded-lg p-4 hidden">
                    <h3 class="text-sm font-semibold text-gray-700 mb-3">Data Summary</h3>
                    <div class="space-y-2">
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600">Total Records:</span>
                            <span id="totalRecords" class="font-bold text-indigo-600">0</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600">Total Amount:</span>
                            <span id="totalAmount" class="font-bold text-green-600">₦0.00</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-gray-600">Period:</span>
                            <span id="selectedPeriod" class="font-bold text-gray-800">-</span>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Right Column: Data Display -->
        <div class="lg:col-span-2">
            <div class="bg-white rounded-xl shadow-lg p-6">
                <div class="flex items-center justify-between mb-4">
                    <h2 class="text-xl font-bold text-gray-800">
                        <i class="fas fa-table mr-2"></i>Staff Data
                    </h2>
                    <div class="flex items-center space-x-2">
                        <input type="text" id="searchInput" placeholder="Search staff..."
                            class="px-3 py-2 border border-gray-300 rounded-lg text-sm focus:ring-2 focus:ring-indigo-500 focus:border-transparent"
                            disabled>
                        <button id="exportBtn" disabled
                            class="px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg text-sm transition-colors disabled:opacity-50 disabled:cursor-not-allowed">
                            <i class="fas fa-file-export mr-1"></i>Export
                        </button>
                    </div>
                </div>

                <!-- Loading State -->
                <div id="loadingState" class="text-center py-12 hidden">
                    <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mb-4">
                    </div>
                    <p class="text-gray-600 font-medium">Fetching data from API...</p>
                    <p class="text-sm text-gray-500 mt-2">Please wait...</p>
                </div>

                <!-- Empty State -->
                <div id="emptyState" class="text-center py-12">
                    <i class="fas fa-cloud-download-alt text-6xl text-gray-300 mb-4"></i>
                    <p class="text-gray-600 font-medium mb-2">No Data Loaded</p>
                    <p class="text-sm text-gray-500">Select a period and click "Fetch Data from API" to begin</p>
                </div>

                <!-- Data Table -->
                <div id="dataTable" class="hidden">
                    <div class="overflow-x-auto">
                        <table class="min-w-full divide-y divide-gray-200">
                            <thead class="bg-gray-50">
                                <tr>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        #
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Staff ID
                                    </th>
                                    <th
                                        class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Name
                                    </th>
                                    <th
                                        class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                                        Amount (₦)
                                    </th>
                                </tr>
                            </thead>
                            <tbody id="tableBody" class="bg-white divide-y divide-gray-200">
                                <!-- Data will be inserted here -->
                            </tbody>
                        </table>
                    </div>

                    <!-- Pagination -->
                    <div class="mt-4 flex items-center justify-between">
                        <div class="text-sm text-gray-600">
                            Showing <span id="showingFrom">0</span> to <span id="showingTo">0</span> of <span
                                id="showingTotal">0</span> records
                        </div>
                        <div class="flex space-x-2">
                            <button id="prevPageBtn"
                                class="px-3 py-1 bg-gray-200 hover:bg-gray-300 rounded text-sm disabled:opacity-50"
                                disabled>
                                Previous
                            </button>
                            <button id="nextPageBtn"
                                class="px-3 py-1 bg-gray-200 hover:bg-gray-300 rounded text-sm disabled:opacity-50"
                                disabled>
                                Next
                            </button>
                        </div>
                    </div>
                </div>

                <!-- Upload Progress -->
                <div id="uploadProgress" class="mt-6 hidden">
                    <div class="bg-blue-50 border border-blue-200 rounded-lg p-4">
                        <div class="flex items-center justify-between mb-2">
                            <span class="text-sm font-medium text-blue-800">Upload Progress</span>
                            <span id="uploadPercent" class="text-sm font-medium text-blue-800">0%</span>
                        </div>
                        <div class="w-full bg-blue-200 rounded-full h-2">
                            <div id="uploadProgressBar" class="bg-blue-600 h-2 rounded-full transition-all duration-300"
                                style="width: 0%"></div>
                        </div>
                        <p id="uploadText" class="text-sm text-blue-700 mt-2">Preparing upload...</p>
                    </div>
                </div>

                <!-- Upload Results -->
                <div id="uploadResults" class="mt-6 hidden"></div>
            </div>
        </div>
    </div>
</div>

<style>
.animate-spin {
    animation: spin 1s linear infinite;
}

@keyframes spin {
    from {
        transform: rotate(0deg);
    }

    to {
        transform: rotate(360deg);
    }
}

.fade-in {
    animation: fadeIn 0.3s ease-in;
}

@keyframes fadeIn {
    from {
        opacity: 0;
        transform: translateY(10px);
    }

    to {
        opacity: 1;
        transform: translateY(0);
    }
}
</style>

<?php include 'includes/footer.php'; ?>

<script>
// Global variables
let apiData = [];
let filteredData = [];
let currentPage = 1;
let recordsPerPage = 50;
let selectedPeriodId = null;
let selectedPeriodInfo = null;

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    console.log('API Upload page initialized');
    loadPeriods();
    setupEventListeners();
});

// Load periods from API
async function loadPeriods() {
    try {
        showApiStatus('connecting', 'Connecting to API...');

        const response = await fetch('api/fetch_api_data.php?action=get_periods');
        const result = await response.json();

        const periodSelect = document.getElementById('apiPeriodSelect');
        periodSelect.innerHTML = '<option value="">Select a period...</option>';

        if (result.success && result.data) {
            showApiStatus('connected', 'Connected');

            result.data.forEach(period => {
                const option = document.createElement('option');
                option.value = period.period_id;
                option.textContent =
                    `${period.description} ${period.year}${period.is_active ? ' (Active)' : ''}`;
                option.dataset.periodInfo = JSON.stringify(period);
                periodSelect.appendChild(option);
            });
        } else {
            showApiStatus('error', result.message || 'Failed to load periods');
            Swal.fire('Error', result.message || 'Failed to load periods from API', 'error');
        }
    } catch (error) {
        console.error('Error loading periods:', error);
        showApiStatus('error', 'Connection failed');
        Swal.fire('Error', 'Failed to connect to API: ' + error.message, 'error');
    }
}

// Show API status
function showApiStatus(status, message) {
    const statusCard = document.getElementById('apiStatusCard');
    const indicator = document.getElementById('statusIndicator');
    const statusText = document.getElementById('statusText');

    statusCard.classList.remove('hidden');
    statusText.textContent = message;

    // Update indicator color
    indicator.classList.remove('bg-green-500', 'bg-yellow-500', 'bg-red-500', 'animate-pulse');

    switch (status) {
        case 'connected':
            indicator.classList.add('bg-green-500');
            break;
        case 'connecting':
            indicator.classList.add('bg-yellow-500', 'animate-pulse');
            break;
        case 'error':
            indicator.classList.add('bg-red-500');
            break;
    }
}

// Setup event listeners
function setupEventListeners() {
    // Period selection
    document.getElementById('apiPeriodSelect').addEventListener('change', function() {
        selectedPeriodId = this.value;
        const selectedOption = this.options[this.selectedIndex];
        selectedPeriodInfo = selectedOption.dataset.periodInfo ? JSON.parse(selectedOption.dataset.periodInfo) :
            null;

        document.getElementById('fetchDataBtn').disabled = !selectedPeriodId;

        // Clear previous data
        clearData();
    });

    // Fetch data button
    document.getElementById('fetchDataBtn').addEventListener('click', fetchData);

    // Upload data button
    document.getElementById('uploadDataBtn').addEventListener('click', uploadData);

    // Clear data button
    document.getElementById('clearDataBtn').addEventListener('click', clearData);

    // Search input
    document.getElementById('searchInput').addEventListener('input', function() {
        filterData(this.value);
    });

    // Export button
    document.getElementById('exportBtn').addEventListener('click', exportToCSV);

    // Pagination buttons
    document.getElementById('prevPageBtn').addEventListener('click', () => changePage(-1));
    document.getElementById('nextPageBtn').addEventListener('click', () => changePage(1));
}

// Fetch data from API
async function fetchData() {
    if (!selectedPeriodId) {
        Swal.fire('Error', 'Please select a period', 'error');
        return;
    }

    // Show loading state
    document.getElementById('emptyState').classList.add('hidden');
    document.getElementById('dataTable').classList.add('hidden');
    document.getElementById('loadingState').classList.remove('hidden');
    document.getElementById('fetchDataBtn').disabled = true;

    try {
        const response = await fetch(`api/fetch_api_data.php?action=get_data&period=${selectedPeriodId}`);
        const result = await response.json();

        if (result.success && result.data) {
            apiData = result.data;
            filteredData = [...apiData];

            // Update stats
            updateStats(result.metadata);

            // Display data
            displayData();

            // Enable controls
            document.getElementById('uploadDataBtn').disabled = false;
            document.getElementById('clearDataBtn').disabled = false;
            document.getElementById('searchInput').disabled = false;
            document.getElementById('exportBtn').disabled = false;

            Swal.fire('Success', `Fetched ${apiData.length} records from API`, 'success');
        } else {
            throw new Error(result.message || 'Failed to fetch data');
        }
    } catch (error) {
        console.error('Error fetching data:', error);
        Swal.fire('Error', 'Failed to fetch data: ' + error.message, 'error');
        document.getElementById('loadingState').classList.add('hidden');
        document.getElementById('emptyState').classList.remove('hidden');
    } finally {
        document.getElementById('fetchDataBtn').disabled = false;
    }
}

// Update stats
function updateStats(metadata) {
    document.getElementById('statsCard').classList.remove('hidden');
    document.getElementById('totalRecords').textContent = metadata.total_records || apiData.length;
    document.getElementById('totalAmount').textContent = '₦' + (metadata.total_amount || 0).toLocaleString('en-NG', {
        minimumFractionDigits: 2
    });
    document.getElementById('selectedPeriod').textContent = `${metadata.period.description} ${metadata.period.year}`;
}

// Display data in table
function displayData() {
    document.getElementById('loadingState').classList.add('hidden');
    document.getElementById('emptyState').classList.add('hidden');
    document.getElementById('dataTable').classList.remove('hidden');

    const tableBody = document.getElementById('tableBody');
    tableBody.innerHTML = '';

    const start = (currentPage - 1) * recordsPerPage;
    const end = Math.min(start + recordsPerPage, filteredData.length);
    const pageData = filteredData.slice(start, end);

    pageData.forEach((item, index) => {
        const row = document.createElement('tr');
        row.className = 'hover:bg-gray-50 fade-in';
        row.innerHTML = `
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${start + index + 1}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${item.staff_id}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${item.name}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-right text-gray-900 font-semibold">₦${parseFloat(item.amount).toLocaleString('en-NG', {minimumFractionDigits: 2})}</td>
        `;
        tableBody.appendChild(row);
    });

    // Update pagination
    updatePagination();
}

// Update pagination controls
function updatePagination() {
    const totalPages = Math.ceil(filteredData.length / recordsPerPage);
    const start = (currentPage - 1) * recordsPerPage + 1;
    const end = Math.min(currentPage * recordsPerPage, filteredData.length);

    document.getElementById('showingFrom').textContent = filteredData.length > 0 ? start : 0;
    document.getElementById('showingTo').textContent = end;
    document.getElementById('showingTotal').textContent = filteredData.length;

    document.getElementById('prevPageBtn').disabled = currentPage === 1;
    document.getElementById('nextPageBtn').disabled = currentPage >= totalPages;
}

// Change page
function changePage(direction) {
    currentPage += direction;
    displayData();
}

// Filter data
function filterData(searchTerm) {
    searchTerm = searchTerm.toLowerCase().trim();

    if (!searchTerm) {
        filteredData = [...apiData];
    } else {
        filteredData = apiData.filter(item =>
            item.staff_id.toLowerCase().includes(searchTerm) ||
            item.name.toLowerCase().includes(searchTerm)
        );
    }

    currentPage = 1;
    displayData();
}

// Upload data to database
async function uploadData() {
    if (apiData.length === 0) {
        Swal.fire('Error', 'No data to upload', 'error');
        return;
    }

    const result = await Swal.fire({
        title: 'Confirm Upload',
        html: `Upload <strong>${apiData.length}</strong> records to database?<br><small class="text-gray-600">Period: ${selectedPeriodInfo.description} ${selectedPeriodInfo.year}</small>`,
        icon: 'question',
        showCancelButton: true,
        confirmButtonText: 'Yes, Upload',
        cancelButtonText: 'Cancel'
    });

    if (!result.isConfirmed) return;

    // Show progress
    document.getElementById('uploadProgress').classList.remove('hidden');
    document.getElementById('uploadDataBtn').disabled = true;

    try {
        const response = await fetch('api/upload_json_data.php', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                period: selectedPeriodId,
                period_info: selectedPeriodInfo,
                resource_type: '<?php echo OOUTH_RESOURCE_TYPE; ?>',
                resource_id: '<?php echo OOUTH_RESOURCE_ID; ?>',
                resource_name: '<?php echo OOUTH_RESOURCE_NAME; ?>',
                data: apiData
            })
        });

        const result = await response.json();

        // Update progress
        document.getElementById('uploadProgressBar').style.width = '100%';
        document.getElementById('uploadPercent').textContent = '100%';
        document.getElementById('uploadText').textContent = 'Upload completed!';

        // Show results
        setTimeout(() => {
            document.getElementById('uploadProgress').classList.add('hidden');

            const resultsDiv = document.getElementById('uploadResults');
            resultsDiv.classList.remove('hidden');

            if (result.success) {
                resultsDiv.innerHTML = `
                    <div class="bg-green-50 border border-green-200 rounded-lg p-4">
                        <div class="flex items-center">
                            <i class="fas fa-check-circle text-green-500 text-2xl mr-3"></i>
                            <div>
                                <p class="text-green-800 font-semibold">Upload Successful!</p>
                                <p class="text-sm text-green-700 mt-1">${result.message}</p>
                                ${result.details ? `<p class="text-xs text-green-600 mt-2">${result.details}</p>` : ''}
                            </div>
                        </div>
                    </div>
                `;
                Swal.fire('Success!', result.message, 'success');
            } else {
                resultsDiv.innerHTML = `
                    <div class="bg-red-50 border border-red-200 rounded-lg p-4">
                        <div class="flex items-center">
                            <i class="fas fa-exclamation-circle text-red-500 text-2xl mr-3"></i>
                            <div>
                                <p class="text-red-800 font-semibold">Upload Failed</p>
                                <p class="text-sm text-red-700 mt-1">${result.message || 'An error occurred'}</p>
                            </div>
                        </div>
                    </div>
                `;
                Swal.fire('Error', result.message || 'Upload failed', 'error');
            }
        }, 500);
    } catch (error) {
        console.error('Upload error:', error);
        document.getElementById('uploadProgress').classList.add('hidden');
        Swal.fire('Error', 'Failed to upload data: ' + error.message, 'error');
    } finally {
        document.getElementById('uploadDataBtn').disabled = false;
    }
}

// Clear data
function clearData() {
    apiData = [];
    filteredData = [];
    currentPage = 1;

    document.getElementById('dataTable').classList.add('hidden');
    document.getElementById('emptyState').classList.remove('hidden');
    document.getElementById('uploadProgress').classList.add('hidden');
    document.getElementById('uploadResults').classList.add('hidden');
    document.getElementById('statsCard').classList.add('hidden');

    document.getElementById('uploadDataBtn').disabled = true;
    document.getElementById('clearDataBtn').disabled = true;
    document.getElementById('searchInput').disabled = true;
    document.getElementById('searchInput').value = '';
    document.getElementById('exportBtn').disabled = true;
}

// Export to CSV
function exportToCSV() {
    if (filteredData.length === 0) {
        Swal.fire('Error', 'No data to export', 'error');
        return;
    }

    const headers = ['Staff ID', 'Name', 'Amount'];
    const rows = filteredData.map(item => [
        item.staff_id,
        item.name,
        item.amount
    ]);

    let csvContent = headers.join(',') + '\n';
    rows.forEach(row => {
        csvContent += row.map(cell => `"${cell}"`).join(',') + '\n';
    });

    const blob = new Blob([csvContent], {
        type: 'text/csv'
    });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${selectedPeriodInfo.description}_${selectedPeriodInfo.year}_${Date.now()}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);

    Swal.fire('Success', 'Data exported to CSV', 'success');
}
</script>