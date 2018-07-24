abstract type Liability end

abstract type Transfer <: Liability end

abstract type Revenue end

abstract type Föräldrarstöd <: Revenue end
abstract type Salary <: Revenue end
abstract type ExternalTransfer <: Revenue end

abstract type Expense end

abstract type Alcohol <: Expense end
abstract type Systembolaget <: Alcohol end
abstract type Bar <: Alcohol end

abstract type Food <: Expense end
abstract type Cafe <: Food end
abstract type Groceries <: Food end
abstract type Restaurant <: Food end

abstract type Health <: Expense end
abstract type Sport <: Health end
abstract type OtherHealth <: Health end

abstract type Transport <: Expense end
abstract type PrivateTransportation <: Transport end
abstract type PublicTransportation <: Transport end

abstract type FastUtgift <: Expense end
abstract type Rent <: FastUtgift end
abstract type Internet <: FastUtgift end
abstract type Electricity <: FastUtgift end
abstract type Phone <: FastUtgift end
abstract type Daycare <: FastUtgift end
abstract type Electricity <: FastUtgift end
abstract type Phone <: FastUtgift end
abstract type PeriodsKort <: FastUtgift end
abstract type CSN <: FastUtgift end

abstract type Shopping <: Expense end

abstract type Fun <: Expense end

abstract type Travel <: Expense end

abstract type OtherExpenses <: Expense end

abstract type Undefined end

ys = Pair{Function, DataType}[]
open(joinpath(Pkg.dir("PersonalBanking"), "src", "categories.csv"), "r") do o
    for l in eachline(o)
        x = split(l, ',')
        a = join(x[2:end], '|')
        f(x) = Regex("(?:$a)", "i")(x) 
        push!(ys, f => include_string(x[1]))
    end
end

function categorize(x) 
    for yt in ys
        y,t = yt
        if y(x)
            return t
        end
    end
    Undefined
end


