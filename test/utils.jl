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
