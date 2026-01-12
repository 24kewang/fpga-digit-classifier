import numpy as np
import re

def read_txt_file(filename):
    """Read flattened 784x1 matrix from text file (one value per line)"""
    with open(filename, 'r') as f:
        values = [float(line.strip()) for line in f if line.strip()]
    return np.array(values).reshape(-1, 1)

def read_coe_file(filename):
    """Read .coe file and extract hex values"""
    with open(filename, 'r') as f:
        content = f.read()
    # print(content[:50])
    content = content.replace("memory_initialization_radix=16;\nmemory_initialization_vector=", "")
    # print(content[:50])
    # Extract all hex values (with or without 0x prefix)
    # Matches patterns like: 0x1234ABCD, 1234ABCD, etc.
    hex_pattern = r'(?:0x)?([0-9A-Fa-f]+)'
    hex_values = re.findall(hex_pattern, content)
    return hex_values

def q16_16_to_float(hex_str):
    """Convert Q16.16 fixed-point hex string to float"""
    # Convert hex string to 32-bit signed integer
    value = int(hex_str, 16)
    
    # Handle two's complement for negative numbers (if MSB is 1)
    if value & 0x80000000:
        value = value - 0x100000000
    
    # Convert to float by dividing by 2^16
    return value / 65536.0

def load_matrix_from_coe(filename, rows, cols):
    """Load matrix from .coe file with Q16.16 hex values"""
    hex_values = read_coe_file(filename)
    
    # Convert hex values to floats
    float_values = [q16_16_to_float(h) for h in hex_values]
    
    # Reshape to matrix (row-major order)
    matrix = np.array(float_values).reshape(rows, cols)
    
    return matrix

def ReLU(Z):
    """ReLU activation function"""
    return np.maximum(0, Z)

def softmax(Z):
    """Softmax activation function"""
    exp_Z = np.exp(Z - np.max(Z))  # Subtract max for numerical stability
    return exp_Z / np.sum(exp_Z, axis=0, keepdims=True)

def forward_prop(W1, b1, W2, b2, X):
    """Forward propagation through the network"""
    Z1 = W1.dot(X) + b1
    A1 = ReLU(Z1)
    Z2 = W2.dot(A1) + b2
    # A2 = softmax(Z2)
    return np.argmax(Z2, 0), Z2

# Main execution
def do_this():
    # File paths
    input_file = 'X.txt'
    w1_file = 'W1.coe'
    w2_file = 'W2.coe'
    b1_file = 'b1.coe'
    b2_file = 'b2.coe'
    
    print("Loading input data...")
    X = read_txt_file(input_file)
    print(f"Input shape: {X.shape}")
    
    print("\nLoading weights and biases...")
    W1 = load_matrix_from_coe(w1_file, 10, 784)
    print(f"W1 shape: {W1.shape}")
    
    W2 = load_matrix_from_coe(w2_file, 10, 10)
    print(f"W2 shape: {W2.shape}")
    
    b1 = load_matrix_from_coe(b1_file, 10, 1)
    print(f"b1 shape: {b1.shape}")
    
    b2 = load_matrix_from_coe(b2_file, 10, 1)
    print(f"b2 shape: {b2.shape}")
    
    print("\nPerforming forward propagation...")
    prediction, max_prob = forward_prop(W1, b1, W2, b2, X)
    
    print(f"\nPredicted digit: {prediction[0]}\nProb: {max_prob}")
    
    # Optional: Show intermediate results
    print("\n--- Detailed Results ---")
    Z1 = W1.dot(X) + b1
    print(Z1)
    A1 = ReLU(Z1)
    print(A1)
    Z2 = W2.dot(A1) + b2
    A2 = softmax(Z2)
    
    # print("\nSoftmax probabilities for each digit:")
    # for i in range(10):
    #     print(f"  Digit {i}: {A2[i, 0]:.6f} ({A2[i, 0] * 100:.2f}%)")
if __name__ == "__main__":
    do_this()