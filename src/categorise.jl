using DataStructures, StringBuilders, Missings

const keyfilename = "keyfile.csv"

const OD = OrderedDict

categories = OD("Liability" => 
                ["Transfer", "Other"], 
                "Expense" => 
                [OD("Food" => 
                    ["Cafe", "Groceries", "Restaurant"]),
                 OD("Alcohol" => 
                    ["Shop", "Bar"]),
                 OD("Health" => 
                    ["Sport", "Other"]),
                 OD("Transport" => 
                    ["Private", "Public"]),
                 OD("FixedCosts" => 
                    ["Rent", "Internet", "Electricity", "Phone", "Daycare", "CSN", "Insurance", "BankCard"]),
                 "Shopping", "Fun", "Travel", "Other"],
                "Revenue" => 
                ["ParentalSupport", "Salary", "ExternalTransfer", "Other"])

cats = String[]
sb = StringBuilder()
n = 0
for (k, vs) in categories
    append!(sb, k, "\n")
    for v in vs
        if v isa OD
            for (k2, v2s) in v
                append!(sb, "\t", k2, "\n")
                for v2 in v2s
                    n += 1
                    append!(sb, "\t\t$n) ", v2, "\n")
                    push!(cats, "$k:$k2:$v2")
                end
            end
        else
            n += 1
            append!(sb, "\t$n) ", v, "\n")
            push!(cats, "$k:$v")
        end
    end
end
msg = String(sb)
print(msg)

function ask(comment, amount, person, date)
    print_with_color(:blue, comment, ", ", amount, " SEK, ", person, ", ", date, '\n')
    run(`googler -c se --np -n 5 $comment`)
    txt = readline()
    if all(isnumber, txt)
        i = parse(Int, txt)
        if 1 ≤ i ≤ n
            return cats[i]
        end
    end
    print_with_color(:red, "must be an integer between 1 and $n\n")
    ask(comment, amount, person, date)
end


function getkey(keyfile)
    key = Dict{String, String}()
    open(keyfile, "r") do o
        for l in eachline(o)
            comment, category = split(l, ",")
            @assert !haskey(key, comment) "found duplicate comment: $comment"
            key[comment] = category
        end
    end
    key
end

function addcomment!(o, key, comment, amount, person, date)
    category = ask(comment, amount, person, date)
    println(o, comment, ",", category)
    key[comment] = category
end


function categorise!(table, folder)
    keyfile = joinpath(folder, keyfilename)
    key = getkey(keyfile)
    table[:category] = ""
    open(keyfile, "a") do o
        for row in DataFrames.eachrow(table)
            comment = row[:description]
            row[:category] = haskey(key, comment) ? key[comment] : addcomment!(o, key, comment, row[:amount], row[:person], row[:date])
        end
    end
    table
end


