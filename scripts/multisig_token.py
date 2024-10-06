from typing import Tuple
from eth_keys import KeyAPI
from eth_keys.backends import NativeECCBackend
from ape import project
from web3 import Web3 # help with hashing

RUToken = project.RUToken

grade_multisig = True # Change this to true if you implemented the multisig token.

keys =  KeyAPI(NativeECCBackend)

class Signature:
    def __init__(self, r: bytes, s: bytes, v: int) -> None:
        self.r = r
        self.s = s
        self.v = v

    # Encode as a tuple suitable for passing as solidity calldata.
    def encoded(self) -> Tuple[bytes, bytes, int]:
        return (self.r, self.s, self.v + 27) # Add 27 to v just because Bitcoin developers decided to use an arbitrary number, and the Ethereum developers copied them.
# This function should return a nonce and a signature 
# that can be passed to transfer2of3.
# Note: The function should *not* change state in any way (e.g., if you call contract methods, call only `view` and `pure` methods`)).
def generate_nonce_and_second_signature_transfer2of3(tok: RUToken, sk, multisigAddr, spender, amount) -> Tuple[int,Signature]: # type: ignore
    key = keys.PrivateKey(bytes.fromhex(sk[2:])) # Can be used with `keys.ecdsa_sign``

    # TODO: Implement
    
    nonce = tok.getNonce(multisigAddr)

    # Structured to prevent replay attacks
    nonce += 1

    print("tok------",tok)
    print("spender------",spender)
    print("multisigAddr------",multisigAddr)

    # hashing the message
    message_hash = Web3.solidity_keccak(['address', 'address', 'address', 'uint256', 'uint256']
                                       , [tok.address, spender.address, multisigAddr, amount, nonce])
    print("message_hash------",message_hash)
    message_signed = keys.ecdsa_sign(message_hash, key)
    print("message_signed------",message_signed)
    print("message_signed.r------",message_signed.r)
    print("message_signed.s------",message_signed.s)
    print("message_signed.v------",message_signed.v + 27)
    multi_signature = Signature(message_signed.r, message_signed.s, message_signed.v)
    print("multi_signature------",multi_signature)
    print("nonce------",nonce)
    
    return (nonce, multi_signature)  # return (0, Signature(b'\0', b'\0', 0)) # Change this!
    


# # This function should return a nonce and a signature that can be passed to transfer2of3.
# def generate_nonce_and_second_signature_transfer2of3(tok: RUToken, sk, multisigAddr, spender, amount) -> Tuple[int,Signature]:
#     """
#     Generate a nonce and a second signature for a 2-out-of-3 multisig transfer.
#     This version does not interact with a contract and uses provided parameters.

#     Parameters:
#     - sk: Hex string private key of the signer (with "0x" prefix).
#     - multisigAddr: Address of the multisig (hex string with "0x" prefix).
#     - spender: Address of the recipient (hex string with "0x" prefix).
#     - amount: Amount to be transferred.
#     - nonce: Nonce for the transaction.

#     Returns:
#     - Tuple containing the nonce and the generated Signature object.
#     """
#     # Ensure the private key is correctly formatted
#     # sk = format_private_key(sk)

#     # Create the private key object using the provided hex string.
#     key = keys.PrivateKey(bytes.fromhex(sk[2:]))  # Convert hex private key to bytes (removing '0x' prefix).

#     # Assuming 'tok' is the contract instance and 'multisigAddr' is an address
#     nonce = tok.getNonce(multisigAddr)  # Call the getter function to retrieve the nonce


#     # Structured to prevent replay attacks
#     nonce += 1

#     # Create a message hash to sign using the provided parameters.
#     message_hash = create_message_hash(tok,multisigAddr, spender, amount, nonce)

#     # Sign the message using the private key.
#     signature = key.sign_msg_hash(message_hash)

#     # Extract r, s, and v from the signature.
#     r = signature.r.to_bytes(32, 'big')
#     s = signature.s.to_bytes(32, 'big')
#     v = signature.v  # Adjust v to match EIP-155 specifications.

#     # Return the nonce and the second signature.
#     return nonce, Signature(r, s, v)

# # Helper function to create the message hash using the input parameters.
# def create_message_hash( sk, multisigAddr, spender, amount, nonce) -> bytes:
#     """
#     Creates a message hash using the multisig address, spender, amount, and nonce.
    
#     Parameters:
#     - multisigAddr: The multisig address as a hex string.
#     - spender: The address of the spender as a hex string.
#     - amount: The amount to be transferred.
#     - nonce: The nonce value to use.
    
#     Returns:
#     - The hash of the encoded message.
#     """
#     # Concatenate the input parameters into a single bytes string.
#     message = (
#         sk  # Convert multisigAddr to bytes.
#         + multisigAddr
#         + spender    # Convert spender to bytes.
#         + amount.to_bytes(32, 'big')   # Convert amount to 32-byte representation.
#         + nonce.to_bytes(32, 'big')    # Convert nonce to 32-byte representation.
#     )

#     # Hash the message using keccak256 and return the result.
#     return keccak(message)


# Example usage:
# if __name__ == "__main__":
#     # Test input parameters.
#     sk = ""  # Sample private key.
#     multisigAddr = "0x14faB4Da20025ddE205C451978c3938fA0a9C5cC"  # Sample multisig address.
#     spender = "0x89F6cdf9056d30669DAC3372E78f186E3C51796D"  # Sample recipient address.
#     amount = 1000000000000000000  # Transfer amount.
#     nonce = 0  # Nonce value.

#     # Generate the nonce and signature.
#     generated_nonce, signature = generate_nonce_and_second_signature_transfer2of3(
#         sk, multisigAddr, spender, amount, nonce
#     )

#     # Print results.
#     print("Generated Nonce:", generated_nonce)
#     print("Generated Signature (r, s, v) in bytes:", signature.encoded())
#     print("Generated Signature (r, s, v) in hex format:", signature.hex_encoded())

