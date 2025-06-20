# 1. Test cases for isnumber function
# -----------------------------------
@testset "isnumber tests" begin
    @test isnumber(5.0) == true
    @test isnumber(-3.2) == true
    @test isnumber(0) == true
    @test isnumber(NaN) == false
    @test isnumber(Inf) == false
    @test isnumber(-Inf) == false
end


# 2. Test cases for fastextrema function
# --------------------------------------

# Test with an array of real numbers
@testset "Real numbers" begin
    data = [1.0, 2.0, 3.0, 4.0, 5.0]
    mini, maxi = fastextrema(data)
    @test mini == 1.0
    @test maxi == 5.0
end

# Test with an array of AbstractFloat numbers containing NaN, Inf, or -Inf
@testset "AbstractFloat with special values" begin
    data = [1.0, NaN, Inf, -Inf, 2.0, 3.0]
    mini, maxi = fastextrema(data)
    @test mini == 1.0
    @test maxi == 3.0
end

# Test with a multi-channel image
@testset "Multi-channel image" begin
    img = rand(RGB{N0f8}, 10, 10)
    mini, maxi = fastextrema(img)
    @test red(mini) <= red(maxi)
    @test green(mini) <= green(maxi)
    @test blue(mini) <= blue(maxi)
end

# Test with a multi-channel image skipper
@testset "Multi-channel image skipper" begin
    img = rand(RGB{N0f8}, 10, 10)
    img[2,2] = RGB(N0f8(0.5), N0f8(0.5), N0f8(0.5))
    mini, maxi = fastextrema(skip(x -> x==RGB(N0f8(0.5), N0f8(0.5), N0f8(0.5)), img))
    @test red(mini) <= red(maxi)
    @test green(mini) <= green(maxi)
    @test blue(mini) <= blue(maxi)
end

# Test with a grayscale image using Skipper.jl
@testset "Grayscale image with Skipper" begin
    img = rand(Gray{N0f8}, 10, 10)
    filtered_img = skip(x -> x < 0.5, img)
    mini, maxi = fastextrema(filtered_img)
    @test mini >= 0.5
    @test maxi >= mini
end

# Test with an unsupported type
@testset "Unsupported type" begin
    unsupported_data = ["a", "b", "c"]
    @test_throws ErrorException fastextrema(unsupported_data)
end


# 3. Test cases for hbox function
# -------------------------------

# Test for basic 2D range without stride
@testset "Basic 2D range without stride" begin
    I = CartesianIndex(3, 3)
    J = CartesianIndex(7, 7)
    result = hbox(I, J)
    expected = CartesianIndices((3:1:7, 3:1:7))
    @test result == expected
end

# Test for 2D range with stride
@testset "2D range with stride" begin
    I = CartesianIndex(3, 3)
    J = CartesianIndex(7, 7)
    stride = CartesianIndex(2, 2)
    result = hbox(I, J, stride=stride)
    expected = CartesianIndices((3:2:7, 3:2:7))
    @test result == expected
end

# Test for 3D range without stride
@testset "Basic 3D range without stride" begin
    I = CartesianIndex(1, 1, 1)
    J = CartesianIndex(4, 4, 4)
    result = hbox(I, J)
    expected = CartesianIndices((1:1:4, 1:1:4, 1:1:4))
    @test result == expected
end

# Test for 3D range with stride
@testset "3D range with stride" begin
    I = CartesianIndex(1, 1, 1)
    J = CartesianIndex(5, 5, 5)
    stride = CartesianIndex(2, 2, 2)
    result = hbox(I, J, stride=stride)
    expected = CartesianIndices((1:2:5, 1:2:5, 1:2:5))
    @test result == expected
end

# Test for subsetting an array using the generated indices
@testset "Subsetting an array" begin
    A = reshape(1:64, 8, 8)
    I = CartesianIndex(3, 3)
    J = CartesianIndex(7, 7)
    indices = hbox(I, J)
    subset = A[indices]
    expected_subset = [19 27 35 43 51; 20 28 36 44 52; 21 29 37 45 53; 22 30 38 46 54; 23 31 39 47 55]
    @test subset == expected_subset
end


# 4. Test cases for bbox function
# -------------------------------

# Test for basic bounding box without margin
@testset "Basic bounding box without margin" begin
    A = [
        false false true false false;
        false true  true false false;
        false false true false false
    ]
    result = bbox(A)
    expected = CartesianIndices((1:1:3, 2:1:3))
    @test result == expected
end

# Test for bounding box with margin
@testset "Bounding box with margin" begin
    A = [
        false false true false false;
        false true  true true  false;
        false false true false false
    ]
    margin = CartesianIndex(1, 1)
    result = bbox(A, margin=margin)
    expected = CartesianIndices((1:1:3, 1:1:5))
    @test result == expected
end

# Test for subsetting an array using the bounding box
@testset "Subsetting an array using the bounding box" begin
    A = [
        false false true false false;
        false true  true false false;
        false false true false false
    ]
    indices = bbox(A)
    subset = A[indices]
    expected = [
        false true;
        true  true;
        false true
    ]
    @test subset == expected
end

# Test for subsetting an array using the bounding box with margin
@testset "Subsetting an array using the bounding box with margin" begin
    A = [
        false false true false false;
        false true  true false false;
        false false true false false
    ]
    margin = CartesianIndex(1, 1)
    indices = bbox(A, margin=margin)
    subset = A[indices]
    expected = [
        false false true false;
        false true  true false;
        false false true false
    ]
    @test subset == expected
end

# Test for bounding box encompassing the entire array when all elements are true
@testset "Bounding box for all true elements" begin
    A = [
        true true true;
        true true true
    ]
    result = bbox(A)
    @test result == CartesianIndices(A)
end

# Test for error when the array contains no `true` values
@testset "Error when no true values" begin
    A = [
        false false false;
        false false false
    ]
    @test_throws ErrorException bbox(A)
end
