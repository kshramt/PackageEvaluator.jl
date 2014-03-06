Pkg.add("Requests")
Pkg.add("JSON")
using Requests

json_head = Dict{String, String}()
json_head["Content-Type"] = "application/json"

# Read in last log file
allfiles = readdir()
logfiles = Any[]
for file in allfiles
    if contains(file, "pkgeval_")
        push!(logfiles,file)
    end
end
sort!(logfiles)
log_data = split(readall(logfiles[end]),"\n")
pkg_log = Dict()
cur_pkg_name = ""
for line in log_data
    if contains(line, "##### Current package")
        cur_pkg_name = strip(split(line, ":")[2])
        pkg_log[cur_pkg_name] = ""
    else
        pkg_log[cur_pkg_name] *= line * "\n"
    end
end

for file in allfiles
    if ismatch(r"json", file)
        json_str = readall(file)
	json_dict = JSON.parse(json_str)
	if json_dict["name"] in keys(pkg_log)
            json_dict["testlog"] = pkg_log[json_dict["name"]]
        else
            json_dict["testlog"] = "No log! Please file issue."
        end
        js2 = open(file,"w")
        print(js2, JSON.json(json_dict))
        close(js2)
	try
	    response = post(URI("http://status.julialang.org/put/package"), JSON.json(json_dict), json_head)
            println(response)
	catch
            println("Failed to post $file, removing log")
            json_dict["testlog"] = "Log error! Please file issue."
	    response = post(URI("http://status.julialang.org/put/package"), JSON.json(json_dict), json_head)
            println(response)
        end
    end
end

Pkg.rm("Requests")
Pkg.rm("JSON")
