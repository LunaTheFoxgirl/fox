import std.stdio;
import std.getopt;
import std.uni;
import std.utf;
import std.range;

bool showAll;
bool showEnds;
bool squeezeBlanks;
bool showTabs;

bool numberNonBlank;
bool numberAll;

bool showHelp;
bool showVersion;


enum HELP_HEADER = "Usage: fox [OPTION]... [FILE]...
Concatenate FILE(s) to standard output.

With no FILE, or when FILE is -, read standard input.
";

void main(string[] args)
{

	// try reading options
	GetoptResult helpInfo;
	try {
		helpInfo = getopt(
			args,
			std.getopt.config.bundling,
			"show-all|A", "Equivalent to -vET", &showAll,
			"number-nonblank|b", "Number non-empty output lines, overrides -n", &numberNonBlank,
			"show-ends|E", "display $ at the end of each line", &showEnds,
			"number|n", "Number all output lines", &numberAll,
			"squeeze-blank|s", "Supress repeated empty output lines", &squeezeBlanks,
			"show-tabs|T", "Display TAB characters as ^I", &showTabs,
			"version", "Output version information and exit", &showVersion,
		);
	} catch(Exception ex) {

		// Error out due to unrecognized option
		writefln("fox: %s\nTry 'fox --help' for more information.", ex.msg);
		return;
	}

	

	// Show version info if needed.
	if (showVersion) {
		writeln("fox 1.0\nCopyright (C) 2022 Luna the Foxgirl.\n\nWritten by Luna the Foxgirl");
		return;
	}

	// Show help text if needed.
	if (helpInfo.helpWanted && args.length != 1) {
		defaultGetoptPrinter(HELP_HEADER, helpInfo.options);
		return;
	}

	if (args.length > 1) {

		// Files and/or STDIO
		foreach(file; args[1..$]) {
			import std.file : readText;
			if (file == "-") printStdio();
			else printFile(readText(file));
		}
	} else {
		// STDIO
		printStdio();
	}
}

void printFile(string f) {
	bool isNewLine = true;
	size_t i;
	size_t ln = 1;
	foreach(g; byGrapheme(f)) {

		if (g[0] == '\t' && showTabs) {
			write("^I");
			i++;
			isNewLine = false;
			continue;
		}

		// Handle getting newline state
		if (g[0] == '\n') {
			if (showEnds) write("$");
			if (isNewLine && squeezeBlanks) continue;
			if (!numberNonBlank && numberAll && isNewLine) putLineNumber(ln);

			write('\n');
			isNewLine = true;
			i++;
			ln++;
			
			continue;
		}

		if ((numberAll || numberNonBlank) && isNewLine) putLineNumber(ln);

		writeChar(g);
		i++;
		isNewLine = false;
	}
}

void putLineNumber(size_t ln) {
	import std.conv : text;
	string lnText = ln.text;

	// Write padding space
	foreach(i; 0..(6-lnText.length)) write(" ");
	
	// Write text and following double space
	write(lnText, "  ");
}

void printStdio() {
	int g = cast(int)getchar();
	while (cast(char)g != '\u0004') {
		writeChar(Grapheme([cast(wchar)g]));
		g = cast(char)getchar();
	}
}

// Character replacment range and character count
const string REPL_CHAR_RANGE = import("charrange.txt");
enum REPL_CHAR_COUNT = 31406;
void writeChar(Grapheme c) {
	import std.random : uniform;

	// Replace random character with random UTF-8 character if need be
	if (uniform(0, 200) < 5) {
		auto grapheme = REPL_CHAR_RANGE.byGrapheme.drop(uniform(0, REPL_CHAR_COUNT)).front();
		write(grapheme[0..grapheme.length]);
		return;
	}

	write(toUTF8(c[0..c.length].array));
	return;
}