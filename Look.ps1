#########################
#
# Variables
#
#########################

$url = "https://data.rivm.nl/covid-19/COVID-19_aantallen_gemeente_per_dag.csv";
$csvPath = ".\" + (Get-Date -Format "dd-MM-yyyy") + ".csv";

$csvFile;

$newCases = 0


Class Province {
	[String]$provinceName;
	$municipalitys;
}

Class Municipality {
	[String] $municipalityName;
	[int] $days;
	
	# cases
	[int] $newCasesLastDay;
	[int] $newCasesLastWeek;
	[int] $newCasesLastMonth;
	[int] $newCasesLastAllTime;
	
	# admission
	[int] $newAdmissionsLastDay;
	[int] $newAdmissionsLastWeek;
	[int] $newAdmissionsLastMonth;
	[int] $newAdmissionsLastAllTime;
	
	# deaths
	[int] $newDeathsLastDay;
	[int] $newDeathsLastWeek;
	[int] $newDeathsLastMonth;
	[int] $newDeathsLastAllTime;
	
	
	[void] NewReport ($newCases, $newAdmisions, $newDeaths) {
		if ($this.days -lt 1) {
			# added for last day
			$this.newCasesLastDay = $newCases;
			$this.newAdmissionsLastDay = $newAdmisions;
			$this.newDeathsLastDay = $newDeaths;
		}
		
		if ($this.days -lt 7) {
			# added for last week
			$this.newCasesLastWeek += $newCases;
			$this.newAdmissionsLastWeek += $newAdmisions;
			$this.newDeathsLastWeek += $newDeaths;
		}
		
		if ($this.days -lt 30) {
			# added for last 30 days
			$this.newCasesLastMonth += $newCases;
			$this.newAdmissionsLastMonth += $newAdmisions;
			$this.newDeathsLastMonth += $newDeaths;
		}
		
		# added all time
		$this.newCasesLastAllTime += $newCases;
		$this.newAdmissionsLastAllTime += $newAdmisions;
		$this.newDeathsLastAllTime += $newDeaths;
		
		$this.days += 1;
	}
}


#########################
#
# Functions
#
#########################
function GetFileFromRIVM () {
	$start_time = Get-Date

	Import-Module BitsTransfer
	Start-BitsTransfer -Source $url -Destination $csvPath
	#OR
	#Start-BitsTransfer -Source $url -Destination $csvPath -Asynchronous

	Write-Host "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
}

function LoadFile () {
	# getlatest file unless already contains
	[IO.FileInfo] $foo = $csvPath
	if (!$foo.Exists) {
		Write-Host "Getting latest file"

		GetFileFromRIVM
	} else {
		Write-Host "Already got the latest file"
	}

	Write-Host 'Reading file'

	# read it
	#$csvFile = Import-Csv -Path $csvPath -Delimiter ';'
	return Import-Csv -Path $csvPath -Delimiter ';' | sort Date_of_publication -Descending
}


function PrintPlace($place) {
	Write-Host "In municipality $($place.municipalityName)" -ForegroundColor White;
	Write-Host "Last day     new cases:$($place.newCasesLastDay) 	|| new admisions:$($place.newAdmissionsLastDay) 	|| new deaths:$($place.newDeathsLastDay)";
	Write-Host "Last week    new cases:$($place.newCasesLastWeek) 	|| new admisions:$($place.newAdmissionsLastWeek) 	|| new deaths:$($place.newDeathsLastWeek)";
	Write-Host "Last 30 days new cases:$($place.newCasesLastMonth) 	|| new admisions:$($place.newAdmissionsLastMonth) 	|| new deaths:$($place.newDeathsLastMonth)";
	Write-Host "Last $($place.days) days    cases:$($place.newCasesLastAllTime) 	|| new admisions:$($place.newAdmissionsLastAllTime) 	|| new deaths:$($place.newDeathsLastAllTime)";
}

#########################
#
# Run program
#
#########################

$csvFile = LoadFile
Write-Host 'Reading file completed'


$provinces = @{};

# update list
foreach ($line in $csvFile) {
	if (!$provinces.ContainsKey($line.Province)) {
		# create new
		$newProvince = New-Object Province;
		
		# set name
		$newProvince.provinceName = $line.Province;
		# make list
		$newProvince.municipalitys = @{};
		
		# add to list
		$provinces.Add($line.Province, $newProvince);
	}
	
	$formatedName = ($line.Municipality_name.Trim()) -replace " ", "-";
	
	if (!$provinces[$line.Province].municipalitys.ContainsKey($formatedName)) {
		# create new
		$newMunicipality = New-Object Municipality;
		
		# set name
		$newMunicipality.municipalityName = $formatedName;
		
		$provinces[$line.Province].municipalitys.Add($formatedName, $newMunicipality);
	}
	
	
	$provinces[$line.Province].municipalitys[$formatedName].NewReport($line.Total_reported, $line.Hospital_admission, $line.Deceased);
}

$Continue = $true;
While ($Continue) {
	clear;
	
	
	# correct province and loop trough
	$correctProvince = $false;
	$selectedProvince;
	while (!$correctProvince) {
		Write-Host "Choose province:" -ForegroundColor White;
		Write-Host $provinces.keys -ForegroundColor Gray;
		$selectedProvince = Read-Host -Prompt 'Input the province';
		

		if ($provinces.ContainsKey($selectedProvince)) {
			$correctProvince = $true;
			clear;
		}
	}


	# correct municipality and loop trough
	$correctMunicipality = $false;
	$selectedMunicipality;
	while (!$correctMunicipality) {
		Write-Host "Choose province:" -ForegroundColor White;
		Write-Host $provinces[$selectedProvince].municipalitys.keys -ForegroundColor Gray;
		$selectedMunicipality = Read-Host -Prompt 'Input the municipality';
		$selectedMunicipality = $selectedMunicipality -replace " ", "-";
		Write-Host $selectedMunicipality;

		if ($provinces[$selectedProvince].municipalitys.ContainsKey($selectedMunicipality)) {
			$correctMunicipality = $true;
			clear;
		}
	}

	# print the place 
	PrintPlace $provinces[$selectedProvince].municipalitys[$selectedMunicipality];
	
	
	# ask to try again
	$wantToStop = Read-Host -Prompt 'type "Yes" to try again';

	if ($wantToStop -eq "Yes") {
		$Continue = $true;
	} else {
		# ask to try again
		$wantToStop2 = Read-Host -Prompt 'type "Yes" to quit';

		if ($wantToStop2 -eq "Yes") {
			$Continue = $false;
		} else {
			$Continue = $true;
		}
	}
}








