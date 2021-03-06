"""
    AbstractDataFrame

An abstract type for which all concrete types expose an interface
for working with tabular data.

# Common methods

An AbstractDataFrame is a two-dimensional table with Symbols for
column names. An AbstractDataFrame is also similar to an Associative
type in that it allows indexing by a key (the columns).

The following are normally implemented for AbstractDataFrames:

* [`describe`](@ref) : summarize columns
* [`summary`](@ref) : show number of rows and columns
* `hcat` : horizontal concatenation
* `vcat` : vertical concatenation
* [`repeat`](@ref) : repeat rows
* `names` : columns names
* [`rename!`](@ref) : rename columns names based on keyword arguments
* `length` : number of columns
* `size` : (nrows, ncols)
* [`first`](@ref) : first `n` rows
* [`last`](@ref) : last `n` rows
* `convert` : convert to an array
* [`completecases`](@ref) : boolean vector of complete cases (rows with no missings)
* [`dropmissing`](@ref) : remove rows with missing values
* [`dropmissing!`](@ref) : remove rows with missing values in-place
* [`nonunique`](@ref) : indexes of duplicate rows
* [`unique!`](@ref) : remove duplicate rows
* [`disallowmissing`](@ref) : drop support for missing values in columns
* [`allowmissing`](@ref) : add support for missing values in columns
* [`categorical`](@ref) : change column types to categorical
* `similar` : a DataFrame with similar columns as `d`
* `filter` : remove rows
* `filter!` : remove rows in-place

# Indexing and broadcasting

`AbstractDataFrame` can be indexed by passing two indices specifying
row and column selectors. The allowed indices are a superset of indices
that can be used for standard arrays. You can also access a single column
of an `AbstractDataFrame` using `getproperty` and `setproperty!` functions.
In broadcasting `AbstractDataFrame` behavior is similar to a `Matrix`.

A detailed description of `getindex`, `setindex!`, `getproperty`, `setproperty!`,
broadcasting and broadcasting assignment for data frames is given in
the ["Indexing" section](https://juliadata.github.io/DataFrames.jl/stable/lib/indexing/) of the manual.

"""
abstract type AbstractDataFrame end

##############################################################################
##
## Basic properties of a DataFrame
##
##############################################################################

"""
    names(df::AbstractDataFrame)

    Return a `Vector{Symbol}` of names of columns contained in `df`.
"""
Base.names(df::AbstractDataFrame) = names(index(df))
_names(df::AbstractDataFrame) = _names(index(df))

Compat.hasproperty(df::AbstractDataFrame, s::Symbol) = haskey(index(df), s)

"""
    rename!(df::AbstractDataFrame, vals::AbstractVector{Symbol}; makeunique::Bool=false)
    rename!(df::AbstractDataFrame, vals::AbstractVector{<:AbstractString}; makeunique::Bool=false)
    rename!(df::AbstractDataFrame, (from => to)::Pair...)
    rename!(df::AbstractDataFrame, d::AbstractDict)
    rename!(df::AbstractDataFrame, d::AbstractArray{<:Pair})
    rename!(f::Function, df::AbstractDataFrame)

Rename columns of `df` in-place.
Each name is changed at most once. Permutation of names is allowed.

# Arguments
- `df` : the `AbstractDataFrame`
- `d` : an `AbstractDict` or an `AbstractVector` of `Pair`s that maps
  the original names or column numbers to new names
- `f` : a function which for each column takes the old name (a `Symbol`)
  and returns the new name that gets converted to a `Symbol`
- `vals` : new column names as a vector of `Symbol`s or `AbstractString`s
  of the same length as the number of columns in `df`
- `makeunique` : if `false` (the default), an error will be raised
  if duplicate names are found; if `true`, duplicate names will be suffixed
  with `_i` (`i` starting at 1 for the first duplicate).

If pairs are passed to `rename!` (as positional arguments or in a dictionary or a vector)
then:
* `from` value can be a `Symbol`, an `AbstractString` or an `Integer`;
* `to` value can be a `Symbol` or an `AbstractString`.

Mixing symbols and strings in `to` and `from` is not allowed.

See also: [`rename`](@ref)

# Examples
```julia
julia> df = DataFrame(i = 1, x = 2, y = 3)
1×3 DataFrame
│ Row │ i     │ x     │ y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename!(df, Dict(:i => "A", :x => "X"))
1×3 DataFrame
│ Row │ A     │ X     │ y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename!(df, [:a, :b, :c])
1×3 DataFrame
│ Row │ a     │ b     │ c     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename!(df, [:a, :b, :a])
ERROR: ArgumentError: Duplicate variable names: :a. Pass makeunique=true to make them unique using a suffix automatically.

julia> rename!(df, [:a, :b, :a], makeunique=true)
1×3 DataFrame
│ Row │ a     │ b     │ a_1   │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename!(df) do x
           uppercase(string(x))
       end
1×3 DataFrame
│ Row │ A     │ B     │ A_1   │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │
```
"""
function rename!(df::AbstractDataFrame, vals::AbstractVector{Symbol};
                 makeunique::Bool=false)
    rename!(index(df), vals, makeunique=makeunique)
    return df
end

function rename!(df::AbstractDataFrame, vals::AbstractVector{<:AbstractString};
                 makeunique::Bool=false)
    rename!(index(df), Symbol.(vals), makeunique=makeunique)
    return df
end

function rename!(df::AbstractDataFrame, args::AbstractVector{Pair{Symbol,Symbol}})
    rename!(index(df), args)
    return df
end

function rename!(df::AbstractDataFrame,
                 args::Union{AbstractVector{<:Pair{Symbol,<:AbstractString}},
                             AbstractVector{<:Pair{<:AbstractString,Symbol}},
                             AbstractVector{<:Pair{<:AbstractString,<:AbstractString}},
                             AbstractDict{Symbol,Symbol},
                             AbstractDict{Symbol,<:AbstractString},
                             AbstractDict{<:AbstractString,Symbol},
                             AbstractDict{<:AbstractString,<:AbstractString}})
    rename!(index(df), [Symbol(from) => Symbol(to) for (from, to) in args])
    return df
end

function rename!(df::AbstractDataFrame,
                 args::Union{AbstractVector{<:Pair{<:Integer,<:AbstractString}},
                             AbstractVector{<:Pair{<:Integer,Symbol}},
                             AbstractDict{<:Integer,<:AbstractString},
                             AbstractDict{<:Integer,Symbol}})
    rename!(index(df), [_names(df)[from] => Symbol(to) for (from, to) in args])
    return df
end

rename!(df::AbstractDataFrame, args::Pair...) = rename!(df, collect(args))

function rename!(f::Function, df::AbstractDataFrame)
    rename!(f, index(df))
    return df
end

"""
    rename(df::AbstractDataFrame, vals::AbstractVector{Symbol}; makeunique::Bool=false)
    rename(df::AbstractDataFrame, vals::AbstractVector{<:AbstractString}; makeunique::Bool=false)
    rename(df::AbstractDataFrame, (from => to)::Pair...)
    rename(df::AbstractDataFrame, d::AbstractDict)
    rename(df::AbstractDataFrame, d::AbstractArray{<:Pair})
    rename(f::Function, df::AbstractDataFrame)

Create a new data frame that is a copy of `df` with changed column names.
Each name is changed at most once. Permutation of names is allowed.

# Arguments
- `df` : the `AbstractDataFrame`
- `d` : an `AbstractDict` or an `AbstractVector` of `Pair`s that maps
  the original names or column numbers to new names
- `f` : a function which for each column takes the old name (a `Symbol`)
  and returns the new name that gets converted to a `Symbol`
- `vals` : new column names as a vector of `Symbol`s or `AbstractString`s
  of the same length as the number of columns in `df`
- `makeunique` : if `false` (the default), an error will be raised
  if duplicate names are found; if `true`, duplicate names will be suffixed
  with `_i` (`i` starting at 1 for the first duplicate).

If pairs are passed to `rename` (as positional arguments or in a dictionary or a vector)
then:
* `from` value can be a `Symbol`, an `AbstractString` or an `Integer`;
* `to` value can be a `Symbol` or an `AbstractString`.

Mixing symbols and strings in `to` and `from` is not allowed.

See also: [`rename!`](@ref)

# Examples
```julia
julia> df = DataFrame(i = 1, x = 2, y = 3)
1×3 DataFrame
│ Row │ i     │ x     │ y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename(df, :i => :A, :x => :X)
1×3 DataFrame
│ Row │ A     │ X     │ y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename(df, :x => :y, :y => :x)
1×3 DataFrame
│ Row │ i     │ y     │ x     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename(df, [1 => :A, 2 => :X])
1×3 DataFrame
│ Row │ A     │ X     │ y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename(df, Dict("i" => "A", "x" => "X"))
1×3 DataFrame
│ Row │ A     │ X     │ y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │

julia> rename(df) do x
           uppercase(string(x))
       end
1×3 DataFrame
│ Row │ I     │ X     │ Y     │
│     │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┤
│ 1   │ 1     │ 2     │ 3     │```
"""
rename(df::AbstractDataFrame, vals::AbstractVector{Symbol};
       makeunique::Bool=false) = rename!(copy(df), vals, makeunique=makeunique)
rename(df::AbstractDataFrame, vals::AbstractVector{<:AbstractString};
       makeunique::Bool=false) = rename!(copy(df), vals, makeunique=makeunique)
rename(df::AbstractDataFrame, args...) = rename!(copy(df), args...)
rename(f::Function, df::AbstractDataFrame) = rename!(f, copy(df))

Base.size(df::AbstractDataFrame) = (nrow(df), ncol(df))
function Base.size(df::AbstractDataFrame, i::Integer)
    if i == 1
        nrow(df)
    elseif i == 2
        ncol(df)
    else
        throw(ArgumentError("DataFrames only have two dimensions"))
    end
end

Base.isempty(df::AbstractDataFrame) = size(df, 1) == 0 || size(df, 2) == 0

Base.lastindex(df::AbstractDataFrame, i::Integer) = last(axes(df, i))
Base.axes(df::AbstractDataFrame, i::Integer) = Base.OneTo(size(df, i))

Base.ndims(::AbstractDataFrame) = 2
Base.ndims(::Type{<:AbstractDataFrame}) = 2

Base.getproperty(df::AbstractDataFrame, col_ind::Symbol) = df[!, col_ind]
# Private fields are never exposed since they can conflict with column names
Base.propertynames(df::AbstractDataFrame, private::Bool=false) = Tuple(_names(df))

##############################################################################
##
## Similar
##
##############################################################################

"""
    similar(df::AbstractDataFrame, rows::Integer=nrow(df))

Create a new `DataFrame` with the same column names and column element types
as `df`. An optional second argument can be provided to request a number of rows
that is different than the number of rows present in `df`.
"""
function Base.similar(df::AbstractDataFrame, rows::Integer = size(df, 1))
    rows < 0 && throw(ArgumentError("the number of rows must be non-negative"))
    DataFrame(AbstractVector[similar(x, rows) for x in eachcol(df)], copy(index(df)),
              copycols=false)
end

##############################################################################
##
## Equality
##
##############################################################################

function Base.:(==)(df1::AbstractDataFrame, df2::AbstractDataFrame)
    size(df1, 2) == size(df2, 2) || return false
    isequal(index(df1), index(df2)) || return false
    eq = true
    for idx in 1:size(df1, 2)
        coleq = df1[!, idx] == df2[!, idx]
        # coleq could be missing
        isequal(coleq, false) && return false
        eq &= coleq
    end
    return eq
end

function Base.isequal(df1::AbstractDataFrame, df2::AbstractDataFrame)
    size(df1, 2) == size(df2, 2) || return false
    isequal(index(df1), index(df2)) || return false
    for idx in 1:size(df1, 2)
        isequal(df1[!, idx], df2[!, idx]) || return false
    end
    return true
end

##############################################################################
##
## Description
##
##############################################################################

"""
    first(df::AbstractDataFrame)

Get the first row of `df` as a `DataFrameRow`.
"""
Base.first(df::AbstractDataFrame) = df[1, :]

"""
    first(df::AbstractDataFrame, n::Integer)

Get a data frame with the `n` first rows of `df`.
"""
Base.first(df::AbstractDataFrame, n::Integer) = df[1:min(n,nrow(df)), :]

"""
    last(df::AbstractDataFrame)

Get the last row of `df` as a `DataFrameRow`.
"""
Base.last(df::AbstractDataFrame) = df[nrow(df), :]

"""
    last(df::AbstractDataFrame, n::Integer)

Get a data frame with the `n` last rows of `df`.
"""
Base.last(df::AbstractDataFrame, n::Integer) = df[max(1,nrow(df)-n+1):nrow(df), :]


"""
    describe(df::AbstractDataFrame; cols=:)
    describe(df::AbstractDataFrame, stats::Union{Symbol, Pair{<:Symbol}}...; cols=:)

Return descriptive statistics for a data frame as a new `DataFrame`
where each row represents a variable and each column a summary statistic.

# Arguments
- `df` : the `AbstractDataFrame`
- `stats::Union{Symbol, Pair{<:Symbol}}...` : the summary statistics to report.
  Arguments can be:
    -  A symbol from the list `:mean`, `:std`, `:min`, `:q25`,
      `:median`, `:q75`, `:max`, `:eltype`, `:nunique`, `:first`, `:last`, and
      `:nmissing`. The default statistics used
      are `:mean`, `:min`, `:median`, `:max`, `:nunique`, `:nmissing`, and `:eltype`.
    - `:all` as the only `Symbol` argument to return all statistics.
    - A `name => function` pair where `name` is a `Symbol`. This will create
      a column of summary statistics with the provided name.
- `cols` : a keyword argument allowing to select only a subset of columns from `df`
  to describe; all standard column selection methods are allowed.

# Details
For `Real` columns, compute the mean, standard deviation, minimum, first quantile, median,
third quantile, and maximum. If a column does not derive from `Real`, `describe` will
attempt to calculate all statistics, using `nothing` as a fall-back in the case of an error.

When `stats` contains `:nunique`, `describe` will report the
number of unique values in a column. If a column's base type derives from `Real`,
`:nunique` will return `nothing`s.

Missing values are filtered in the calculation of all statistics, however the column
`:nmissing` will report the number of missing values of that variable.
If the column does not allow missing values, `nothing` is returned.
Consequently, `nmissing = 0` indicates that the column allows
missing values, but does not currently contain any.

If custom functions are provided, they are called repeatedly with the vector corresponding
to each column as the only argument. For columns allowing for missing values,
the vector is wrapped in a call to [`skipmissing`](@ref): custom functions must therefore
support such objects (and not only vectors), and cannot access missing values.

# Examples
```julia
julia> df = DataFrame(i=1:10, x=0.1:0.1:1.0, y='a':'j')
10×3 DataFrame
│ Row │ i     │ x       │ y    │
│     │ Int64 │ Float64 │ Char │
├─────┼───────┼─────────┼──────┤
│ 1   │ 1     │ 0.1     │ 'a'  │
│ 2   │ 2     │ 0.2     │ 'b'  │
│ 3   │ 3     │ 0.3     │ 'c'  │
│ 4   │ 4     │ 0.4     │ 'd'  │
│ 5   │ 5     │ 0.5     │ 'e'  │
│ 6   │ 6     │ 0.6     │ 'f'  │
│ 7   │ 7     │ 0.7     │ 'g'  │
│ 8   │ 8     │ 0.8     │ 'h'  │
│ 9   │ 9     │ 0.9     │ 'i'  │
│ 10  │ 10    │ 1.0     │ 'j'  │

julia> describe(df)
3×8 DataFrame
│ Row │ variable │ mean   │ min │ median │ max │ nunique │ nmissing │ eltype   │
│     │ Symbol   │ Union… │ Any │ Union… │ Any │ Union…  │ Nothing  │ DataType │
├─────┼──────────┼────────┼─────┼────────┼─────┼─────────┼──────────┼──────────┤
│ 1   │ i        │ 5.5    │ 1   │ 5.5    │ 10  │         │          │ Int64    │
│ 2   │ x        │ 0.55   │ 0.1 │ 0.55   │ 1.0 │         │          │ Float64  │
│ 3   │ y        │        │ 'a' │        │ 'j' │ 10      │          │ Char     │

julia> describe(df, :min, :max)
3×3 DataFrame
│ Row │ variable │ min │ max │
│     │ Symbol   │ Any │ Any │
├─────┼──────────┼─────┼─────┤
│ 1   │ i        │ 1   │ 10  │
│ 2   │ x        │ 0.1 │ 1.0 │
│ 3   │ y        │ 'a' │ 'j' │

julia> describe(df, :min, :sum => sum)
3×3 DataFrame
│ Row │ variable │ min │ sum │
│     │ Symbol   │ Any │ Any │
├─────┼──────────┼─────┼─────┤
│ 1   │ i        │ 1   │ 55  │
│ 2   │ x        │ 0.1 │ 5.5 │
│ 3   │ y        │ 'a' │     │

julia> describe(df, :min, :sum => sum, cols=:x)
1×3 DataFrame
│ Row │ variable │ min     │ sum     │
│     │ Symbol   │ Float64 │ Float64 │
├─────┼──────────┼─────────┼─────────┤
│ 1   │ x        │ 0.1     │ 5.5     │
```
"""
DataAPI.describe(df::AbstractDataFrame, stats::Union{Symbol, Pair{Symbol}}...; cols=:) =
    _describe(select(df, cols, copycols=false), collect(stats))

DataAPI.describe(df::AbstractDataFrame; cols=:) =
    _describe(select(df, cols, copycols=false),
              [:mean, :min, :median, :max, :nunique, :nmissing, :eltype])

function _describe(df::AbstractDataFrame, stats::AbstractVector)
    predefined_funs = Symbol[s for s in stats if s isa Symbol]

    allowed_fields = [:mean, :std, :min, :q25, :median, :q75,
                      :max, :nunique, :nmissing, :first, :last, :eltype]

    if predefined_funs == [:all]
        predefined_funs = allowed_fields
        i = findfirst(s -> s == :all, stats)
        splice!(stats, i, allowed_fields) # insert in the stats vector to get a good order
    elseif :all in predefined_funs
        throw(ArgumentError("`:all` must be the only `Symbol` argument."))
    elseif !issubset(predefined_funs, allowed_fields)
        not_allowed = join(setdiff(predefined_funs, allowed_fields), ", :")
        allowed_msg = "\nAllowed fields are: :" * join(allowed_fields, ", :")
        throw(ArgumentError(":$not_allowed not allowed." * allowed_msg))
    end

    custom_funs = Pair[s for s in stats if s isa Pair]

    ordered_names = [s isa Symbol ? s : s[1] for s in stats]

    if !allunique(ordered_names)
        duplicate_names = unique(ordered_names[nonunique(DataFrame(ordered_names = ordered_names))])
        throw(ArgumentError("Duplicate names not allowed. Duplicated value(s) are: " *
                            ":$(join(duplicate_names, ", "))"))
    end

    # Put the summary stats into the return data frame
    data = DataFrame()
    data.variable = names(df)

    # An array of Dicts for summary statistics
    column_stats_dicts = map(eachcol(df)) do col
        if eltype(col) >: Missing
            t = collect(skipmissing(col))
            d = get_stats(t, predefined_funs)
            get_stats!(d, t, custom_funs)
        else
            d = get_stats(col, predefined_funs)
            get_stats!(d, col, custom_funs)
        end

        if :nmissing in predefined_funs
            d[:nmissing] = eltype(col) >: Missing ? count(ismissing, col) : nothing
        end

        if :first in predefined_funs
            d[:first] = isempty(col) ? nothing : first(col)
        end

        if :last in predefined_funs
            d[:last] = isempty(col) ? nothing : last(col)
        end

        if :eltype in predefined_funs
            d[:eltype] = eltype(col)
        end

        return d
    end

    for stat in ordered_names
        # for each statistic, loop through the columns array to find values
        # letting the comprehension choose the appropriate type
        data[!, stat] = [column_stats_dict[stat] for column_stats_dict in column_stats_dicts]
    end

    return data
end

# Compute summary statistics
# use a dict because we dont know which measures the user wants
# Outside of the `describe` function due to something with 0.7
function get_stats(col::AbstractVector, stats::AbstractVector{Symbol})
    d = Dict{Symbol, Any}()

    if :q25 in stats || :median in stats || :q75 in stats
        q = try quantile(col, [.25, .5, .75]) catch; (nothing, nothing, nothing) end
        d[:q25] = q[1]
        d[:median] = q[2]
        d[:q75] = q[3]
    end

    if :min in stats || :max in stats
        ex = try extrema(col) catch; (nothing, nothing) end
        d[:min] = ex[1]
        d[:max] = ex[2]
    end

    if :mean in stats || :std in stats
        m = try mean(col) catch end
        # we can add non-necessary things to d, because we choose what we need
        # in the main function
        d[:mean] = m

        if :std in stats
            d[:std] = try std(col, mean = m) catch end
        end
    end

    if :nunique in stats
        if eltype(col) <: Real
            d[:nunique] = nothing
        else
            d[:nunique] = try length(unique(col)) catch end
        end
    end

    return d
end

function get_stats!(d::Dict, col::AbstractVector, stats::AbstractVector{<:Pair})
    for stat in stats
        d[stat[1]] = try stat[2](col) catch end
    end
end


##############################################################################
##
## Miscellaneous
##
##############################################################################

function _nonmissing!(res, col)
    @inbounds for (i, el) in enumerate(col)
        res[i] &= !ismissing(el)
    end
    return nothing
end

function _nonmissing!(res, col::CategoricalArray{>: Missing})
    for (i, el) in enumerate(col.refs)
        res[i] &= el > 0
    end
    return nothing
end


"""
    completecases(df::AbstractDataFrame, cols::Colon=:)
    completecases(df::AbstractDataFrame, cols::Union{AbstractVector, Regex, Not, Between, All})
    completecases(df::AbstractDataFrame, cols::Union{Integer, Symbol})

Return a Boolean vector with `true` entries indicating rows without missing values
(complete cases) in data frame `df`. If `cols` is provided, only missing values in
the corresponding columns are considered.

See also: [`dropmissing`](@ref) and [`dropmissing!`](@ref).
Use `findall(completecases(df))` to get the indices of the rows.

# Examples

```julia
julia> df = DataFrame(i = 1:5,
                      x = [missing, 4, missing, 2, 1],
                      y = [missing, missing, "c", "d", "e"])
5×3 DataFrame
│ Row │ i     │ x       │ y       │
│     │ Int64 │ Int64⍰  │ String⍰ │
├─────┼───────┼─────────┼─────────┤
│ 1   │ 1     │ missing │ missing │
│ 2   │ 2     │ 4       │ missing │
│ 3   │ 3     │ missing │ c       │
│ 4   │ 4     │ 2       │ d       │
│ 5   │ 5     │ 1       │ e       │

julia> completecases(df)
5-element BitArray{1}:
 false
 false
 false
  true
  true

julia> completecases(df, :x)
5-element BitArray{1}:
 false
  true
 false
  true
  true

julia> completecases(df, [:x, :y])
5-element BitArray{1}:
 false
 false
 false
  true
  true
```
"""
function completecases(df::AbstractDataFrame, col::Colon=:)
    if ncol(df) == 0
        throw(ArgumentError("Unable to compute complete cases of a data frame with no columns"))
    end
    res = trues(size(df, 1))
    for i in 1:size(df, 2)
        _nonmissing!(res, df[!, i])
    end
    res
end

function completecases(df::AbstractDataFrame, col::ColumnIndex)
    res = trues(size(df, 1))
    _nonmissing!(res, df[!, col])
    res
end

completecases(df::AbstractDataFrame, cols::Union{AbstractVector, Regex, Not, Between, All}) =
    completecases(df[!, cols])

"""
    dropmissing(df::AbstractDataFrame, cols::Colon=:; disallowmissing::Bool=true)
    dropmissing(df::AbstractDataFrame, cols::Union{AbstractVector, Regex, Not, Between, All};
                disallowmissing::Bool=true)
    dropmissing(df::AbstractDataFrame, cols::Union{Integer, Symbol};
                disallowmissing::Bool=true)

Return a copy of data frame `df` excluding rows with missing values.
If `cols` is provided, only missing values in the corresponding columns are considered.

If `disallowmissing` is `true` (the default) then columns specified in `cols` will
be converted so as not to allow for missing values using [`disallowmissing!`](@ref).

See also: [`completecases`](@ref) and [`dropmissing!`](@ref).

# Examples

```julia
julia> df = DataFrame(i = 1:5,
                      x = [missing, 4, missing, 2, 1],
                      y = [missing, missing, "c", "d", "e"])
5×3 DataFrame
│ Row │ i     │ x       │ y       │
│     │ Int64 │ Int64⍰  │ String⍰ │
├─────┼───────┼─────────┼─────────┤
│ 1   │ 1     │ missing │ missing │
│ 2   │ 2     │ 4       │ missing │
│ 3   │ 3     │ missing │ c       │
│ 4   │ 4     │ 2       │ d       │
│ 5   │ 5     │ 1       │ e       │

julia> dropmissing(df)
2×3 DataFrame
│ Row │ i     │ x     │ y      │
│     │ Int64 │ Int64 │ String │
├─────┼───────┼───────┼────────┤
│ 1   │ 4     │ 2     │ d      │
│ 2   │ 5     │ 1     │ e      │

julia> dropmissing(df, disallowmissing=false)
2×3 DataFrame
│ Row │ i     │ x      │ y       │
│     │ Int64 │ Int64⍰ │ String⍰ │
├─────┼───────┼────────┼─────────┤
│ 1   │ 4     │ 2      │ d       │
│ 2   │ 5     │ 1      │ e       │

julia> dropmissing(df, :x)
3×3 DataFrame
│ Row │ i     │ x     │ y       │
│     │ Int64 │ Int64 │ String⍰ │
├─────┼───────┼───────┼─────────┤
│ 1   │ 2     │ 4     │ missing │
│ 2   │ 4     │ 2     │ d       │
│ 3   │ 5     │ 1     │ e       │

julia> dropmissing(df, [:x, :y])
2×3 DataFrame
│ Row │ i     │ x     │ y      │
│     │ Int64 │ Int64 │ String │
├─────┼───────┼───────┼────────┤
│ 1   │ 4     │ 2     │ d      │
│ 2   │ 5     │ 1     │ e      │
```
"""
function dropmissing(df::AbstractDataFrame,
                     cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon}=:;
                     disallowmissing::Bool=true)
    newdf = df[completecases(df, cols), :]
    disallowmissing && disallowmissing!(newdf, cols)
    newdf
end

"""
    dropmissing!(df::AbstractDataFrame, cols::Colon=:; disallowmissing::Bool=true)
    dropmissing!(df::AbstractDataFrame, cols::Union{AbstractVector, Regex, Not, Between, All};
                 disallowmissing::Bool=true)
    dropmissing!(df::AbstractDataFrame, cols::Union{Integer, Symbol};
                 disallowmissing::Bool=true)

Remove rows with missing values from data frame `df` and return it.
If `cols` is provided, only missing values in the corresponding columns are considered.

If `disallowmissing` is `true` (the default) then the `cols` columns will
get converted using [`disallowmissing!`](@ref).

See also: [`dropmissing`](@ref) and [`completecases`](@ref).

```jldoctest
julia> df = DataFrame(i = 1:5,
                      x = [missing, 4, missing, 2, 1],
                      y = [missing, missing, "c", "d", "e"])
5×3 DataFrame
│ Row │ i     │ x       │ y       │
│     │ Int64 │ Int64⍰  │ String⍰ │
├─────┼───────┼─────────┼─────────┤
│ 1   │ 1     │ missing │ missing │
│ 2   │ 2     │ 4       │ missing │
│ 3   │ 3     │ missing │ c       │
│ 4   │ 4     │ 2       │ d       │
│ 5   │ 5     │ 1       │ e       │

julia> dropmissing!(copy(df))
2×3 DataFrame
│ Row │ i     │ x     │ y      │
│     │ Int64 │ Int64 │ String │
├─────┼───────┼───────┼────────┤
│ 1   │ 4     │ 2     │ d      │
│ 2   │ 5     │ 1     │ e      │

julia> dropmissing!(copy(df), disallowmissing=false)
2×3 DataFrame
│ Row │ i     │ x      │ y       │
│     │ Int64 │ Int64⍰ │ String⍰ │
├─────┼───────┼────────┼─────────┤
│ 1   │ 4     │ 2      │ d       │
│ 2   │ 5     │ 1      │ e       │

julia> dropmissing!(copy(df), :x)
3×3 DataFrame
│ Row │ i     │ x     │ y       │
│     │ Int64 │ Int64 │ String⍰ │
├─────┼───────┼───────┼─────────┤
│ 1   │ 2     │ 4     │ missing │
│ 2   │ 4     │ 2     │ d       │
│ 3   │ 5     │ 1     │ e       │

julia> dropmissing!(df3, [:x, :y])
2×3 DataFrame
│ Row │ i     │ x     │ y      │
│     │ Int64 │ Int64 │ String │
├─────┼───────┼───────┼────────┤
│ 1   │ 4     │ 2     │ d      │
│ 2   │ 5     │ 1     │ e      │
```
"""
function dropmissing!(df::AbstractDataFrame,
                      cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon}=:;
                      disallowmissing::Bool=true)
    deleterows!(df, (!).(completecases(df, cols)))
    disallowmissing && disallowmissing!(df, cols)
    df
end

"""
    filter(function, df::AbstractDataFrame)

Return a copy of data frame `df` containing only rows for which `function`
returns `true`. The function is passed a `DataFrameRow` as its only argument.

# Examples
```
julia> df = DataFrame(x = [3, 1, 2, 1], y = ["b", "c", "a", "b"])
4×2 DataFrame
│ Row │ x     │ y      │
│     │ Int64 │ String │
├─────┼───────┼────────┤
│ 1   │ 3     │ b      │
│ 2   │ 1     │ c      │
│ 3   │ 2     │ a      │
│ 4   │ 1     │ b      │

julia> filter(row -> row[:x] > 1, df)
2×2 DataFrame
│ Row │ x     │ y      │
│     │ Int64 │ String │
├─────┼───────┼────────┤
│ 1   │ 3     │ b      │
│ 2   │ 2     │ a      │
```
"""
Base.filter(f, df::AbstractDataFrame) = df[collect(f(r)::Bool for r in eachrow(df)), :]

"""
    filter!(function, df::AbstractDataFrame)

Remove rows from data frame `df` for which `function` returns `false`.
The function is passed a `DataFrameRow` as its only argument.

# Examples
```
julia> df = DataFrame(x = [3, 1, 2, 1], y = ["b", "c", "a", "b"])
4×2 DataFrame
│ Row │ x     │ y      │
│     │ Int64 │ String │
├─────┼───────┼────────┤
│ 1   │ 3     │ b      │
│ 2   │ 1     │ c      │
│ 3   │ 2     │ a      │
│ 4   │ 1     │ b      │

julia> filter!(row -> row[:x] > 1, df);

julia> df
2×2 DataFrame
│ Row │ x     │ y      │
│     │ Int64 │ String │
├─────┼───────┼────────┤
│ 1   │ 3     │ b      │
│ 2   │ 2     │ a      │
```
"""
Base.filter!(f, df::AbstractDataFrame) =
    deleterows!(df, findall(collect(!f(r)::Bool for r in eachrow(df))))

function Base.convert(::Type{Matrix}, df::AbstractDataFrame)
    T = reduce(promote_type, (eltype(v) for v in eachcol(df)))
    convert(Matrix{T}, df)
end
function Base.convert(::Type{Matrix{T}}, df::AbstractDataFrame) where T
    n, p = size(df)
    res = Matrix{T}(undef, n, p)
    idx = 1
    for (name, col) in eachcol(df, true)
        try
            copyto!(res, idx, col)
        catch err
            if err isa MethodError && err.f == convert &&
               !(T >: Missing) && any(ismissing, col)
                throw(ArgumentError("cannot convert a DataFrame containing missing values to Matrix{$T} " *
                                    "(found for column $name)"))
            else
                rethrow(err)
            end
        end
        idx += n
    end
    return res
end
Base.Matrix(df::AbstractDataFrame) = Base.convert(Matrix, df)
Base.Matrix{T}(df::AbstractDataFrame) where {T} = Base.convert(Matrix{T}, df)

Base.convert(::Type{Array}, df::AbstractDataFrame) = convert(Matrix, df)
Base.convert(::Type{Array{T}}, df::AbstractDataFrame) where {T}  = Matrix{T}(df)
Base.Array(df::AbstractDataFrame) = Matrix(df)
Base.Array{T}(df::AbstractDataFrame) where {T} = Matrix{T}(df)

"""
    nonunique(df::AbstractDataFrame)
    nonunique(df::AbstractDataFrame, cols)

Return a `Vector{Bool}` in which `true` entries indicate duplicate rows.
A row is a duplicate if there exists a prior row with all columns containing
equal values (according to `isequal`).

See also [`unique`](@ref) and [`unique!`](@ref).

# Arguments
- `df` : the AbstractDataFrame
- `cols` : a column indicator (Symbol, Int, Vector{Symbol}, etc.)
  specifying the column(s) to compare

# Examples
```julia
df = DataFrame(i = 1:10, x = rand(10), y = rand(["a", "b", "c"], 10))
df = vcat(df, df)
nonunique(df)
nonunique(df, 1)
```
"""
function nonunique(df::AbstractDataFrame)
    if ncol(df) == 0
        throw(ArgumentError("finding duplicate rows in data frame with no columns is not allowed"))
    end
    gslots = row_group_slots(ntuple(i -> df[!, i], ncol(df)), Val(true))[3]
    # unique rows are the first encountered group representatives,
    # nonunique are everything else
    res = fill(true, nrow(df))
    @inbounds for g_row in gslots
        (g_row > 0) && (res[g_row] = false)
    end
    return res
end

nonunique(df::AbstractDataFrame, cols) = nonunique(select(df, cols, copycols=false))

Base.unique!(df::AbstractDataFrame) = deleterows!(df, findall(nonunique(df)))
Base.unique!(df::AbstractDataFrame, cols::AbstractVector) =
    deleterows!(df, findall(nonunique(df, cols)))
Base.unique!(df::AbstractDataFrame, cols) =
    deleterows!(df, findall(nonunique(df, cols)))

# Unique rows of an AbstractDataFrame.
Base.unique(df::AbstractDataFrame) = df[(!).(nonunique(df)), :]
Base.unique(df::AbstractDataFrame, cols) =
    df[(!).(nonunique(df, cols)), :]

"""
    unique(df::AbstractDataFrame)
    unique(df::AbstractDataFrame, cols)
    unique!(df::AbstractDataFrame)
    unique!(df::AbstractDataFrame, cols)

Delete duplicate rows of data frame `df`, keeping only the first occurrence of unique rows.
When `cols` is specified, the return DataFrame contains complete rows,
retaining in each case the first instance for which `df[cols]` is unique.

When `unique` is called a new data frame is returned; `unique!` updates `df` in-place.

See also [`nonunique`](@ref).

# Arguments
- `df` : the AbstractDataFrame
- `cols` :  column indicator (Symbol, Int, Vector{Symbol}, Regex, etc.)
specifying the column(s) to compare.

# Examples
```julia
df = DataFrame(i = 1:10, x = rand(10), y = rand(["a", "b", "c"], 10))
df = vcat(df, df)
unique(df)   # doesn't modify df
unique(df, 1)
unique!(df)  # modifies df
```
"""
(unique, unique!)

function without(df::AbstractDataFrame, icols::Vector{<:Integer})
    newcols = setdiff(1:ncol(df), icols)
    view(df, :, newcols)
end
without(df::AbstractDataFrame, i::Int) = without(df, [i])
without(df::AbstractDataFrame, c::Any) = without(df, index(df)[c])

"""
    hcat(df::AbstractDataFrame...;
         makeunique::Bool=false, copycols::Bool=true)
    hcat(df::AbstractDataFrame..., vs::AbstractVector;
         makeunique::Bool=false, copycols::Bool=true)
    hcat(vs::AbstractVector, df::AbstractDataFrame;
         makeunique::Bool=false, copycols::Bool=true)

Horizontally concatenate `AbstractDataFrames` and optionally `AbstractVector`s.

If `AbstractVector` is passed then a column name for it is automatically generated
as `:x1` by default.

If `makeunique=false` (the default) column names of passed objects must be unique.
If `makeunique=true` then duplicate column names will be suffixed
with `_i` (`i` starting at 1 for the first duplicate).

If `copycols=true` (the default) then the `DataFrame` returned by `hcat` will
contain copied columns from the source data frames.
If `copycols=false` then it will contain columns as they are stored in the
source (without copying). This option should be used with caution as mutating
either the columns in sources or in the returned `DataFrame` might lead to
the corruption of the other object.

# Example
```jldoctest
julia [DataFrame(A=1:3) DataFrame(B=1:3)]
3×2 DataFrame
│ Row │ A     │ B     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 1     │
│ 2   │ 2     │ 2     │
│ 3   │ 3     │ 3     │

julia> df1 = DataFrame(A=1:3, B=1:3);

julia> df2 = DataFrame(A=4:6, B=4:6);

julia> df3 = hcat(df1, df2, makeunique=true)
3×4 DataFrame
│ Row │ A     │ B     │ A_1   │ B_1   │
│     │ Int64 │ Int64 │ Int64 │ Int64 │
├─────┼───────┼───────┼───────┼───────┤
│ 1   │ 1     │ 1     │ 4     │ 4     │
│ 2   │ 2     │ 2     │ 5     │ 5     │
│ 3   │ 3     │ 3     │ 6     │ 6     │

julia> df3.A === df1.A
false

julia> df3 = hcat(df1, df2, makeunique=true, copycols=false);

julia> df3.A === df1.A
true
```
"""
Base.hcat(df::AbstractDataFrame; makeunique::Bool=false, copycols::Bool=true) =
    DataFrame(df, copycols=copycols)
Base.hcat(df::AbstractDataFrame, x; makeunique::Bool=false, copycols::Bool=true) =
    hcat!(DataFrame(df, copycols=copycols), x,
          makeunique=makeunique, copycols=copycols)
Base.hcat(x, df::AbstractDataFrame; makeunique::Bool=false, copycols::Bool=true) =
    hcat!(x, df, makeunique=makeunique, copycols=copycols)
Base.hcat(df1::AbstractDataFrame, df2::AbstractDataFrame;
          makeunique::Bool=false, copycols::Bool=true) =
    hcat!(DataFrame(df1, copycols=copycols), df2,
          makeunique=makeunique, copycols=copycols)
Base.hcat(df::AbstractDataFrame, x, y...;
          makeunique::Bool=false, copycols::Bool=true) =
    hcat!(hcat(df, x, makeunique=makeunique, copycols=copycols), y...,
          makeunique=makeunique, copycols=copycols)
Base.hcat(df1::AbstractDataFrame, df2::AbstractDataFrame, dfn::AbstractDataFrame...;
          makeunique::Bool=false, copycols::Bool=true) =
    hcat!(hcat(df1, df2, makeunique=makeunique, copycols=copycols), dfn...,
          makeunique=makeunique, copycols=copycols)

"""
    vcat(dfs::AbstractDataFrame...; cols::Union{Symbol, AbstractVector{Symbol}}=:setequal)

Vertically concatenate `AbstractDataFrame`s.

The `cols` keyword argument determines the columns of the returned data frame:

* `:setequal`: require all data frames to have the same column names disregarding order.
  If they appear in different orders, the order of the first provided data frame is used.
* `:orderequal`: require all data frames to have the same column names and in the same order.
* `:intersect`: only the columns present in *all* provided data frames are kept.
  If the intersection is empty, an empty data frame is returned.
* `:union`: columns present in *at least one* of the provided data frames are kept.
  Columns not present in some data frames are filled with `missing` where necessary.
* A vector of `Symbol`s: only listed columns are kept.
  Columns not present in some data frames are filled with `missing` where necessary.

The order of columns is determined by the order they appear in the included data frames,
searching through the header of the first data frame, then the second, etc.

The element types of columns are determined using `promote_type`,
as with `vcat` for `AbstractVector`s.

`vcat` ignores empty data frames, making it possible to initialize an empty
data frame at the beginning of a loop and `vcat` onto it.

# Example
```jldoctest
julia> df1 = DataFrame(A=1:3, B=1:3);

julia> df2 = DataFrame(A=4:6, B=4:6);

julia> df3 = DataFrame(A=7:9, C=7:9);

julia> d4 = DataFrame();

julia> vcat(df1, df2)
6×2 DataFrame
│ Row │ A     │ B     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 1     │
│ 2   │ 2     │ 2     │
│ 3   │ 3     │ 3     │
│ 4   │ 4     │ 4     │
│ 5   │ 5     │ 5     │
│ 6   │ 6     │ 6     │

julia> vcat(df1, df3, cols=:union)
6×3 DataFrame
│ Row │ A     │ B       │ C       │
│     │ Int64 │ Int64⍰  │ Int64⍰  │
├─────┼───────┼─────────┼─────────┤
│ 1   │ 1     │ 1       │ missing │
│ 2   │ 2     │ 2       │ missing │
│ 3   │ 3     │ 3       │ missing │
│ 4   │ 7     │ missing │ 7       │
│ 5   │ 8     │ missing │ 8       │
│ 6   │ 9     │ missing │ 9       │

julia> vcat(df1, df3, cols=:intersect)
6×1 DataFrame
│ Row │ A     │
│     │ Int64 │
├─────┼───────┤
│ 1   │ 1     │
│ 2   │ 2     │
│ 3   │ 3     │
│ 4   │ 7     │
│ 5   │ 8     │
│ 6   │ 9     │

julia> vcat(d4, df1)
3×2 DataFrame
│ Row │ A     │ B     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 1     │
│ 2   │ 2     │ 2     │
│ 3   │ 3     │ 3     │
```

"""
Base.vcat(dfs::AbstractDataFrame...;
          cols::Union{Symbol, AbstractVector{Symbol}}=:setequal) =
    reduce(vcat, dfs; cols=cols)

Base.reduce(::typeof(vcat),
            dfs::Union{AbstractVector{<:AbstractDataFrame}, Tuple{Vararg{AbstractDataFrame}}};
            cols::Union{Symbol, AbstractVector{Symbol}}=:setequal) =
    _vcat([df for df in dfs if ncol(df) != 0]; cols=cols)

function _vcat(dfs::AbstractVector{<:AbstractDataFrame};
               cols::Union{Symbol, AbstractVector{Symbol}}=:setequal)

    isempty(dfs) && return DataFrame()
    # Array of all headers
    allheaders = map(names, dfs)
    # Array of unique headers across all data frames
    uniqueheaders = unique(allheaders)
    # All symbols present across all headers
    unionunique = union(uniqueheaders...)
    # List of symbols present in all dataframes
    intersectunique = intersect(uniqueheaders...)

    if cols === :orderequal
        header = unionunique
        if length(uniqueheaders) > 1
            throw(ArgumentError("when `cols=:orderequal` all data frames need to have the same column names " *
                                "and be in the same order"))
        end
    elseif cols === :setequal || cols === :equal
        if cols === :equal
            Base.depwarn("`cols=:equal` is deprecated." *
                         "Use `:setequal` instead.", :vcat)
        end

        header = unionunique
        coldiff = setdiff(unionunique, intersectunique)

        if !isempty(coldiff)
            # if any DataFrames are a full superset of names, skip them
            filter!(u -> !issetequal(u, header), uniqueheaders)
            estrings = map(enumerate(uniqueheaders)) do (i, head)
                matching = findall(h -> head == h, allheaders)
                headerdiff = setdiff(coldiff, head)
                cols = join(headerdiff, ", ", " and ")
                args = join(matching, ", ", " and ")
                return "column(s) $cols are missing from argument(s) $args"
            end
            throw(ArgumentError(join(estrings, ", ", ", and ")))
        end
    elseif cols === :intersect
        header = intersectunique
    elseif cols === :union
        header = unionunique
    elseif cols isa Symbol
        throw(ArgumentError("Invalid `cols` value :$cols. " *
                            "Only `:orderequal`, `:setequal`, `:intersect`, " *
                            "`:union`, or a vector of column names is allowed."))
    else
        header = cols
    end

    length(header) == 0 && return DataFrame()
    all_cols = Vector{AbstractVector}(undef, length(header))
    for (i, name) in enumerate(header)
        newcols = map(dfs) do df
            if hasproperty(df, name)
                return df[!, name]
            else
                Iterators.repeated(missing, nrow(df))
            end
        end

        lens = map(length, newcols)
        T = mapreduce(eltype, promote_type, newcols)
        all_cols[i] = Tables.allocatecolumn(T, sum(lens))
        offset = 1
        for j in 1:length(newcols)
            copyto!(all_cols[i], offset, newcols[j])
            offset += lens[j]
        end
    end
    return DataFrame(all_cols, header, copycols=false)
end

"""
    repeat(df::AbstractDataFrame; inner::Integer = 1, outer::Integer = 1)

Construct a data frame by repeating rows in `df`. `inner` specifies how many
times each row is repeated, and `outer` specifies how many times the full set
of rows is repeated.

# Example
```jldoctest
julia> df = DataFrame(a = 1:2, b = 3:4)
2×2 DataFrame
│ Row │ a     │ b     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 3     │
│ 2   │ 2     │ 4     │

julia> repeat(df, inner = 2, outer = 3)
12×2 DataFrame
│ Row │ a     │ b     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 3     │
│ 2   │ 1     │ 3     │
│ 3   │ 2     │ 4     │
│ 4   │ 2     │ 4     │
│ 5   │ 1     │ 3     │
│ 6   │ 1     │ 3     │
│ 7   │ 2     │ 4     │
│ 8   │ 2     │ 4     │
│ 9   │ 1     │ 3     │
│ 10  │ 1     │ 3     │
│ 11  │ 2     │ 4     │
│ 12  │ 2     │ 4     │
```
"""
Base.repeat(df::AbstractDataFrame; inner::Integer = 1, outer::Integer = 1) =
    mapcols(x -> repeat(x, inner = inner, outer = outer), df)

"""
    repeat(df::AbstractDataFrame, count::Integer)

Construct a data frame by repeating each row in `df` the number of times
specified by `count`.

# Example
```jldoctest
julia> df = DataFrame(a = 1:2, b = 3:4)
2×2 DataFrame
│ Row │ a     │ b     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 3     │
│ 2   │ 2     │ 4     │

julia> repeat(df, 2)
4×2 DataFrame
│ Row │ a     │ b     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 3     │
│ 2   │ 2     │ 4     │
│ 3   │ 1     │ 3     │
│ 4   │ 2     │ 4     │
```
"""
Base.repeat(df::AbstractDataFrame, count::Integer) =
    mapcols(x -> repeat(x, count), df)

##############################################################################
##
## Hashing
##
##############################################################################

const hashdf_seed = UInt == UInt32 ? 0xfd8bb02e : 0x6215bada8c8c46de

function Base.hash(df::AbstractDataFrame, h::UInt)
    h += hashdf_seed
    h += hash(size(df))
    for i in 1:size(df, 2)
        h = hash(df[!, i], h)
    end
    return h
end

Base.parent(adf::AbstractDataFrame) = adf
Base.parentindices(adf::AbstractDataFrame) = axes(adf)

## Documentation for methods defined elsewhere

function nrow end
function ncol end

"""
    nrow(df::AbstractDataFrame)
    ncol(df::AbstractDataFrame)

Return the number of rows or columns in an `AbstractDataFrame` `df`.

See also [`size`](@ref).

**Examples**

```jldoctest
julia> df = DataFrame(i = 1:10, x = rand(10), y = rand(["a", "b", "c"], 10));

julia> size(df)
(10, 3)

julia> nrow(df)
10

julia> ncol(df)
3
```

"""
(nrow, ncol)

"""
    disallowmissing(df::AbstractDataFrame,
                    cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon}=:;
                    error::Bool=true)

Return a copy of data frame `df` with columns `cols` converted
from element type `Union{T, Missing}` to `T` to drop support for missing values.

If `cols` is omitted all columns in the data frame are converted.

If `error=false` then columns containing a `missing` value will be skipped instead of throwing an error.

**Examples**

```jldoctest
julia> df = DataFrame(a=Union{Int,Missing}[1,2])
2×1 DataFrame
│ Row │ a      │
│     │ Int64⍰ │
├─────┼────────┤
│ 1   │ 1      │
│ 2   │ 2      │

julia> disallowmissing(df)
2×1 DataFrame
│ Row │ a     │
│     │ Int64 │
├─────┼───────┤
│ 1   │ 1     │
│ 2   │ 2     │
```

julia> df = DataFrame(a=[1,missing])
2×2 DataFrame
│ Row │ a       │ b      │
│     │ Int64⍰  │ Int64⍰ │
├─────┼─────────┼────────┤
│ 1   │ 1       │ 1      │
│ 2   │ missing │ 2      │

julia> disallowmissing(df, error=false)
2×2 DataFrame
│ Row │ a       │ b     │
│     │ Int64⍰  │ Int64 │
├─────┼─────────┼───────┤
│ 1   │ 1       │ 1     │
│ 2   │ missing │ 2     │
"""
function Missings.disallowmissing(df::AbstractDataFrame,
                                  cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon}=:;
                                  error::Bool=true)
    idxcols = Set(index(df)[cols])
    newcols = AbstractVector[]
    for i in axes(df, 2)
        x = df[!, i]
        if i in idxcols
            if !error && Missing <: eltype(x) && any(ismissing, x)
                y = x
            else
                y = disallowmissing(x)
            end
            push!(newcols, y === x ? copy(y) : y)
        else
            push!(newcols, copy(x))
        end
    end
    DataFrame(newcols, _names(df), copycols=false)
end

"""
    allowmissing(df::AbstractDataFrame,
                 cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon}=:)

Return a copy of data frame `df` with columns `cols` converted
to element type `Union{T, Missing}` from `T` to allow support for missing values.

If `cols` is omitted all columns in the data frame are converted.

**Examples**

```jldoctest
julia> df = DataFrame(a=[1,2])
2×1 DataFrame
│ Row │ a     │
│     │ Int64 │
├─────┼───────┤
│ 1   │ 1     │
│ 2   │ 2     │

julia> allowmissing(df)
2×1 DataFrame
│ Row │ a      │
│     │ Int64⍰ │
├─────┼────────┤
│ 1   │ 1      │
│ 2   │ 2      │
```
"""
function Missings.allowmissing(df::AbstractDataFrame,
                               cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon}=:)
    idxcols = Set(index(df)[cols])
    newcols = AbstractVector[]
    for i in axes(df, 2)
        x = df[!, i]
        if i in idxcols
            y = allowmissing(x)
            push!(newcols, y === x ? copy(y) : y)
        else
            push!(newcols, copy(x))
        end
    end
    DataFrame(newcols, _names(df), copycols=false)
end

"""
    categorical(df::AbstractDataFrame, cols::Type=Union{AbstractString, Missing};
                compress::Bool=false)
    categorical(df::AbstractDataFrame,
                cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon};
                compress::Bool=false)

Return a copy of data frame `df` with columns `cols` converted to `CategoricalVector`.
If `categorical` is called with the `cols` argument being a `Type`, then
all columns whose element type is a subtype of this type
(by default `Union{AbstractString, Missing}`) will be converted to categorical.

If the `compress` keyword argument is set to `true` then the created `CategoricalVector`s
will be compressed.

All created `CategoricalVector`s are unordered.

**Examples**

```jldoctest
julia> df = DataFrame(a=[1,2], b=["a","b"])
2×2 DataFrame
│ Row │ a     │ b      │
│     │ Int64 │ String │
├─────┼───────┼────────┤
│ 1   │ 1     │ a      │
│ 2   │ 2     │ b      │

julia> categorical(df)
2×2 DataFrame
│ Row │ a     │ b            │
│     │ Int64 │ Categorical… │
├─────┼───────┼──────────────┤
│ 1   │ 1     │ a            │
│ 2   │ 2     │ b            │

julia> categorical(df, :)
2×2 DataFrame
│ Row │ a            │ b            │
│     │ Categorical… │ Categorical… │
├─────┼──────────────┼──────────────┤
│ 1   │ 1            │ a            │
│ 2   │ 2            │ b            │
```
"""
function CategoricalArrays.categorical(df::AbstractDataFrame,
                                       cols::Union{ColumnIndex, AbstractVector, Regex, Not, Between, All, Colon};
                                       compress::Bool=false)
    idxcols = Set(index(df)[cols])
    newcols = AbstractVector[]
    for i in axes(df, 2)
        x = df[!, i]
        if i in idxcols
            # categorical always copies
            push!(newcols, categorical(x, compress))
        else
            push!(newcols, copy(x))
        end
    end
    DataFrame(newcols, _names(df), copycols=false)
end

function CategoricalArrays.categorical(df::AbstractDataFrame,
                                       cols::Type=Union{AbstractString, Missing};
                                       compress::Bool=false)
    newcols = AbstractVector[]
    for i in axes(df, 2)
        x = df[!, i]
        if eltype(x) <: cols
            # categorical always copies
            push!(newcols, categorical(x, compress))
        else
            push!(newcols, copy(x))
        end
    end
    DataFrame(newcols, _names(df), copycols=false)
end

"""
    flatten(df::AbstractDataFrame, col::Union{Integer, Symbol})

When column `col` of data frame `df` has iterable elements that define `length` (for example
a `Vector` of `Vector`s), return a `DataFrame` where each element of `col` is flattened, meaning
the column corresponding to `col` becomes a longer `Vector` where the original entries
are concatenated. Elements of row `i` of `df` in columns other than `col` will be repeated
according to the length of `df[i, col]`. Note that these elements are not copied,
and thus if they are mutable changing them in the returned `DataFrame` will affect `df`.

# Examples

```
julia> df1 = DataFrame(a = [1, 2], b = [[1, 2], [3, 4]])
2×2 DataFrame
│ Row │ a     │ b      │
│     │ Int64 │ Array… │
├─────┼───────┼────────┤
│ 1   │ 1     │ [1, 2] │
│ 2   │ 2     │ [3, 4] │

julia> flatten(df1, :b)
4×2 DataFrame
│ Row │ a     │ b     │
│     │ Int64 │ Int64 │
├─────┼───────┼───────┤
│ 1   │ 1     │ 1     │
│ 2   │ 1     │ 2     │
│ 3   │ 2     │ 3     │
│ 4   │ 2     │ 4     │

julia> df2 = DataFrame(a = [1, 2], b = [("p", "q"), ("r", "s")])
2×2 DataFrame
│ Row │ a     │ b          │
│     │ Int64 │ Tuple…     │
├─────┼───────┼────────────┤
│ 1   │ 1     │ ("p", "q") │
│ 2   │ 2     │ ("r", "s") │

julia> flatten(df2, :b)
4×2 DataFrame
│ Row │ a     │ b      │
│     │ Int64 │ String │
├─────┼───────┼────────┤
│ 1   │ 1     │ p      │
│ 2   │ 1     │ q      │
│ 3   │ 2     │ r      │
│ 4   │ 2     │ s      │

```
"""
function flatten(df::AbstractDataFrame, col::ColumnIndex)
    col_to_flatten = df[!, col]
    lengths = length.(col_to_flatten)
    new_df = similar(df[!, Not(col)], sum(lengths))

    for name in _names(new_df)
        repeat_lengths!(new_df[!, name], df[!, name], lengths)
    end

    flattened_col = col_to_flatten isa AbstractVector{<:AbstractVector} ?
        reduce(vcat, col_to_flatten) :
        collect(Iterators.flatten(col_to_flatten))

    insertcols!(new_df, columnindex(df, col), col => flattened_col)

    return new_df
end

function repeat_lengths!(longnew::AbstractVector, shortold::AbstractVector, lengths::AbstractVector{Int})
    counter = 1
    @inbounds for i in eachindex(shortold)
        l = lengths[i]
        longnew[counter:(counter + l - 1)] .= Ref(shortold[i])
        counter += l
    end
end
