require 'date';
require 'erb';
require 'fileutils';

info = `defaults read $(pwd)/binaries/Queued.app/Contents/Info.plist`
version = /CFBundleShortVersionString.*=\s*"(.*)";/.match(info)[1]
build = /CFBundleVersion.*=\s*(.*);/.match(info)[1]

zipFile = "binaries/Queued-%{version}.zip" % {:version => version}
system("zip -r %{zipFile} binaries/Queued.app > /dev/null" % { :zipFile => zipFile })
zipSize = File.size(zipFile)
FileUtils.rm_r "binaries/Queued.app"

b = binding
puts ERB.new(<<-'END'.gsub(/^\s+/, "")).result b
<item>
	<title>Version <%= version %></title>
	<description><![CDATA[
		]]></description>
	<sparkle:minimumSystemVersion>10.8.0</sparkle:minimumSystemVersion>
	<pubDate><%= DateTime.now().strftime("%a, %d %b %Y %H:%M:%S %Z") %></pubDate>
	<enclosure url="http://queuedupdates.appspot.com/binaries/Queued-<%= version %>.zip"
		sparkle:version="<%= build %>" sparkle:shortVersionString="<%= version %>" length="<%= zipSize %>" type="application/octet-stream"/>
</item>
END