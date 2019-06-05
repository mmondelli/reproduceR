CREATE TABLE "input_output" (
	input_output_id INTEGER NOT NULL PRIMARY KEY,
	name TEXT,
	type TEXT
);
CREATE TABLE os (
	os_id INTEGER NOT NULL PRIMARY KEY,
	name TEXT,
	platform TEXT
);
CREATE TABLE "parameter" (
	parameter_id INTEGER NOT NULL PRIMARY KEY,
	name TEXT,
	value TEXT
);
CREATE TABLE script (
	script_id INTEGER NOT NULL PRIMARY KEY,
	script_name TEXT,
	start_time TEXT,
	duration NUMERIC
);
CREATE TABLE "user" (
	user_id INTEGER NOT NULL PRIMARY KEY,
	name TEXT,
	os_id INTEGER REFERENCES os(os_id) ON DELETE CASCADE
);
CREATE TABLE os_package (
	os_package_id INTEGER NOT NULL PRIMARY KEY,
	os_package_name TEXT,
	version TEXT,
	os_id INTEGER REFERENCES os(os_id) ON DELETE CASCADE,
	script_id INTEGER REFERENCES script(script_id) ON DELETE CASCADE
);
CREATE TABLE script_package (
	script_package_id INTEGER NOT NULL PRIMARY KEY,
	script_package_name TEXT,
	repository TEXT,
	version TEXT,
	os_package_id INTEGER REFERENCES os_package(os_package_id) ON DELETE CASCADE
);
CREATE TABLE "function" (
	function_id INTEGER NOT NULL PRIMARY KEY,
	name TEXT,
	script_id INTEGER REFERENCES script(script_id) ON DELETE CASCADE,
	script_package_id INTEGER REFERENCES script_package(script_package_id) ON DELETE CASCADE
);
CREATE TABLE consumed (
	consumed_id INTEGER NOT NULL PRIMARY KEY,
	input_id INTEGER REFERENCES "input_output"(input_output_id) ON DELETE CASCADE,
	function_id INTEGER REFERENCES "function"(function_id) ON DELETE CASCADE,
	parameters TEXT 
);
CREATE TABLE produced (
	produced_id INTEGER NOT NULL PRIMARY KEY,
	output_id INTEGER REFERENCES "input_output"(input_output_id) ON DELETE CASCADE,
	funtion_id INTEGER REFERENCES "function"(function_id) ON DELETE CASCADE
);

