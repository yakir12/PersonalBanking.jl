__precompile__()

module PersonalBanking

export main, categorise!

using ExcelReaders, DataFrames, CSV, StringDistances

include(joinpath(Pkg.dir("PersonalBanking"), "src", "categorise.jl"))

const rawdata = "/home/yakir/documents/money/rawdata"

function cleandescription(X)
    x = lowercase(X)
    x = replace(x, r"ö", 'o')
    x = replace(x, r"ä", 'a')
    x = replace(x, r"å", 'a')
    x = replace(x, r"[^a-z0-9]", ' ')
    join(unique(split(x)), ' ')
end

function fixdescription(x)::String
    m = match(r"^[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\s?(.*)", x)
    if m ≠ nothing
        strip(first(m.captures))
    else
        strip(x)
    end
end

function excelskandia(file)
    f = openxl(file)
    sheetname = "Kontoutdrag"
    sheet = f.workbook[:sheet_by_name](sheetname)
    startrow, startcol, endrow, endcol = ExcelReaders.convert_args_to_row_col(sheet)
    a = readxl(f, "$(sheetname)!A5:C$endrow")
    description = cleandescription.(fixdescription.(string.(a[:,2])))
    df = DataFrame(date = Date.(strip.(a[:,1])), description = description, amount = float.(a[:,3]))
    sort!(df, :date)
end

fixdate(x) = Date(strip(x)) - Date(0,1,1) + Date(2000,1,1)

function excelswedbank(file)
    f = openxl(file)
    sheetname = "Blad1"
    sheet = f.workbook[:sheet_by_name](sheetname)
    startrow, startcol, endrow, endcol = ExcelReaders.convert_args_to_row_col(sheet)
    date = readxl(f, "$(sheetname)!E6:E$endrow")
    description = readxl(f, "$(sheetname)!G6:G$endrow")
    amount = readxl(f, "$(sheetname)!I6:I$endrow")
    description = cleandescription.(string.(vec(description)))
    df = DataFrame(date = fixdate.(vec(date)), description = description, amount = float.(vec(amount)))
    sort!(df, :date)
end

fixsum(x) = parse(Float64, replace(filter(!isspace, x), ',', '.'))

function csvswedbank(file)
    a = CSV.read(file, delim = ';', header = ["description", "transaktionsdatum", "date", "amount", "saldo"], missingstring = "-")
    dropmissing!(a)
    disallowmissing!(a)
    a[:date] = Date.(a[:date])
    a[:amount] = fixsum.(a[:amount])
    a[:description] .= cleandescription.(a[:description])
    sort!(a[:, [:date, :description, :amount]], :date)
    # a = CSV.read(file, delim = ';', transforms = Dict{Int, Function}(1 => x -> strip(string(x)), 2 => x -> Date(x), 3 => identity, 4 => fixsum, 5 => identity), header = ["description", "a", "date", "amount", "b"])
end

function loadbank(person, ext, file)
    if person == "yakir"
        excelskandia(file)
    else
        if ext == ".csv"
            csvswedbank(file)
        else
            excelswedbank(file)
        end
    end
end

function overlap(t1, t2)
    date, description, amount = convert(Array, t1[end, :])
    date < t2[1, :date] && return 1
    i1 = findfirst(x -> x ≥ date - Dates.Day(1), t2[:date])
    i2 = findlast(x -> x ≤ date + Dates.Day(1), t2[:date])
    i1 == i2 && return i1 + 1
    candidates = filter(i -> amount - 1 ≤ t2[i, :amount] ≤ amount + 1, i1:i2)
    isempty(candidates) && return 1
    length(candidates) == 1 && return candidates[1] + 1
    _, i = findmax(compare(Hamming(), description, t2[candidate, :description]) for candidate in candidates)
    candidates[i] + 1
end

function concatenate!(t1, t2)
    t1, t2 = t1[end, :date] < t2[end, :date] ? (t1, t2) : (t2, t1)
    i = overlap(t1, t2)
    append!(t1, t2[i:end, :])
end

function getall()
    all = Dict("yakir" => Dict{String, DataFrame}(), "ninna" => Dict{String, DataFrame}())
    for f in readdir(rawdata)
        if f[1] ≠ '.'
            file = joinpath(rawdata, f)
            person, account, rest = split(f, '_')
            _, ext = splitext(rest)
            bank = loadbank(person, ext, file)
            bank[:account] = Symbol(account)
            bank[:person] = Symbol(person)
            if haskey(all[person], account)
                concatenate!(all[person][account], bank)
            else
                all[person][account] = bank
            end
        end
    end
    all
end

function gather(a)
    table = DataFrame(date = Date(1), description = "", amount = 0.0, account = :a, person = :b)
    deleterows!(table, 1)
    for person in values(a), account in values(person)
        append!(table, account)
    end
    sort!(table, :date)
end

main() = gather(getall())

end # module


#=badwords = ["malmo", "lund", "till", "montreal", "koebenhavn", "haifa", "fran", "milano", "francisco", "san", "kastrup", "stockholm", "malm", "tel", "aviv", "triangeln", "durham", "the", "nya", "och", "eslov", "via", "brugge", "goteborg", "firenze", "molndal", "oslo", "ltd", "com", "www", "vaxjo", "ab"]

goodword(w) = length(w) > 1 && w ∉ badwords

function break2labels(Str)
    str = lowercase(Str)
    str = replace(str, r"ö", 'o')
    str = replace(str, r"ä", 'a')
    str = replace(str, r"å", 'a')
    str = replace(str, r"[^a-z0-9]", ' ')
    txts::Vector{String} = split(str)
    utxts = unique(strip.(txts))
    # filter!(goodword, utxts)
end

regexit(words) = isempty(words) ? r"" : Regex(string("[", join(words, "|"), "]"))


a = main()
d = a[:description]

uds = unique(break2labels(u) for u in d)

for i in d
    s = 0
    words = break2labels(i)
    for u in uds
        if 
            s += 1
        end
    end
    println(s)
end

find(uds, 
# a[:label] = join.(break2labels.(a[:description]), " ")

a = main()
d = a[:description]
uds = unique(break2labels(u) for u in d)
# sum(length, uds)
words = cat(1, uds...)
x = countmap(words)
w = collect(keys(x))
c = collect(values(x))
o = sortperm(c, rev=true)
y = OrderedDict(w[i] => c[i] for i in o)

x = SortedDict(x)

y = sort(x, by=last)

i = 105
d[i]
break2labels(d[i])

for j in 1:length(uds)
    u = uds[j]
    n = length(u)
    if n > 1
        for i in 1:n - 1
            if u[1:i] ∉ uds
                uds[j] = u[1:i]
            end
        end
    end
end

sum(length, uds)











a = main()

msg = """
Liability
    1) Transfer
    2) Other

Expense
    Food
        3) Cafe
        4) Groceries
        5) Restaurant

    Alcohol
        6) Store
        7) Bar

    Health
        8) Sport
        9) Other

    Transport
        10) Private
        11) Public

    FixedCost
        12) Rent
        13) Internet
        14) Electricity
        15) Phone
        16) Daycare
        17) CSN

    18) Shopping

    19) Fun

    20) Travel

    21) Other

Revenue
    22) ParentalSupport
    23) Salary
    24) ExternalTransfer
    25) Other

26) Undefined
"""

categories = [:Transfer, :Cafe, :Groceries, :Restaurant, :Systembolaget, :Bar, :Sport, :OtherHealth, :PrivateTransportation, :PublicTransportation, :Rent, :Internet, :Electricity, :Phone, :Daycare, :Electricity, :Phone, :PeriodsKort, :CSN, :Shopping, :Fun, :Travel, :OtherExpenses, :Föräldrarstöd, :Salary, :ExternalTransfer, :Undefined]
c = zeros(Int, nrow(a))
for i in 1:1#nrow(a)
    println(a[i,:])
    println(msg)
    x = readline()
    c[i] = parse(Int, x)
end



b = filter(x -> x[:category] <: Undefined, a)
open("tmp.txt", "w") do o
    println.(o, b[:description])
end

const days = Dates.Day.([0, -1, 1])
function findtransfer(a, i)::Union{Missing, Int}
    for d in days
        date = a[i, :date] + d
        i1 = findfirst(x -> x == date, a[:date])
        i1 == 0 && continue
        i2 = findlast(x -> x == date, a[:date])
        i2 == 0 && continue
        for ii in i1:i2
            if a[ii, :amount] == -a[i, :amount] 
                return ii
            end
        end
    end
    return missing
end

tokill = Vector{Pair{Int, Int}}()
for i in 1:nrow(a)
    if a[i, :amount] > 0
        ii = findtransfer(a, i)
        if !ismissing(ii)
            push!(tokill, Pair(i, ii))
        end
    end
end

function findtransfer(r, a)::Union{Missing, Int}
    r[:amount] ≥ 0 && return missing
    i1 = findfirst(x -> x[:date] ≥ r[:date] - d, eachrow(a))
    i2 = findlast(x -> x[:date] ≤ r[:date] + d, eachrow(a))
    candidates = filter(i -> a[i, :amount] == -r[:amount], i1:i2)
    isempty(candidates) && return missing
    _, i = findmax(compare(Hamming(), r[:description], a[candidate, :description]) for candidate in candidates)
    candidates[i]
end

transfer(x) = r"(?:Insättning|plutt|SUGARMAMA|yakirhuvud2yakirbuffert|ninnalön2ninnahuvud|buffert|Övf|unknown|Överföring|swish|Insättning)"i(x)


i1 = findfirst(x -> x[:amount] > 0, eachrow(a))
i2 = 
struct Transfer
    i1::Int
    i2::Int
    d::Dates.Day
end
ps = Dict{Float64, Vector{Transfer}}()
for i in i1:i2 - 1
    if a[i, :amount] > 0 && transfer((a[i, :description]))
        for j in i + 1:i2
            if a[i, :amount] == -a[j, :amount] && transfer(a[j, :description])
                Δ = abs(a[i, :date] - a[j, :date])
                if haskey(ps, a[j, :amount])
                    push!(ps[a[i, :amount]], Transfer(i, j, Δ))
                else
                    ps[a[i, :amount]] = [Transfer(i, j, Δ)]
                end
            end
        end
    end
end

for (k,v) in ps
    while !isempty(v)
        _, i = findmin(x.d for x in v)
        m = v[i]
        push!(tokill, Pair(m.i1, m.i2))
        filter!(x -> x.i1 ≠ m.i1 && x.i2 ≠ m.i2, v)
    end
end



tokill = Vector{Pair{Int, Int}}()
for i1 = 1:nrow(a)
    _i2 = findlast(j -> a[j, :date] ≤ a[i, :date] + d, rng)



    function distance(a, i, j)
        if a[i, :amount] == -a[j, :amount] && transfer(a[j, :description])
            abs(a[i, :date] - a[j, :date])
        else
            Dates.Day(10000)
        end
    end


    d = Dates.Day(3)
    tokill = Vector{Pair{Int, Int}}()
    for i in 1:nrow(a) - 1
        if a[i, :amount] < 0 && transfer((a[i, :description]))
            rng = i+1:nrow(a)
            _i2 = findlast(j -> a[j, :date] ≤ a[i, :date] + d, rng)
            if _i2 ≠ 0
                rng = rng[1:_i2]
                v, j = findmin(distance(a, i, j) for j in rng)
                if v ≠ Dates.Day(10000)
                    push!(tokill, i => rng[j])
                end
            end
        end
    end


    for i in 1:nrow(a)
        j 
        d = [distance(a, i, j) for i = 1:nrow(a), j = 1:nrow(a)]

        for r1 in eachrow(a), r2 in eachrow(a)

            d = Dates.Day(1)
            tokill = Vector{Pair{Int, Int}}()
            for (i, r) in enumerate(eachrow(a))
                j = findtransfer(r, a)
                if !ismissing(j) && j ∉ last.(
                                              push!(tokill, i => j)
                                          end
                                      end

                                      open("tmp.txt", "w") do o
                                          for k in tokill
                                              i,j = k
                                              println(o, i, j, a[[i,j], :])
                                          end
                                      end

a = ["Comment" "Category";
     "2018-06-10 ICA SUPERMARKET SODER, MALMO" "Expense:Food:Groceries"; 
     "2018-06-05 SKANETRAFIKEN, MALMO C" "Expense:Transport:Public"]
=#
