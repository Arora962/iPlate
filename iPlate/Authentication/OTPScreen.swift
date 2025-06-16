//
//  OTPScreen.swift
//  iPlate
//
//


import SwiftUI

struct OTPScreen: View {
    var email: String
    var generatedOTP: String
    var originalPassword: String

    @State private var enteredOTP = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Text("Verify Email")
                .font(.title)
                .bold()

            Text("Enter the OTP sent to \(email)")
                .font(.subheadline)
                .multilineTextAlignment(.center)

            TextField("Enter OTP", text: $enteredOTP)
                .keyboardType(.numberPad)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

            // Re-enter Password
            HStack {
                Group {
                    if isPasswordVisible {
                        TextField("Re-enter Password", text: $confirmPassword)
                    } else {
                        SecureField("Re-enter Password", text: $confirmPassword)
                    }
                }
                .padding()

                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gray)
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)

            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            Button("Verify & Complete Signup") {
                verifyOTP()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.orange)
            .foregroundColor(.white)
            .cornerRadius(20)

            if showSuccess {
                Text("Signup Complete!\nAutomatically Redirecting Back..")
                    .foregroundColor(.green)
                    .lineLimit(nil)
            }
        }
        .padding()
    }

    private func verifyOTP() {
        guard enteredOTP == generatedOTP else {
            errorMessage = "Invalid OTP."
            return
        }

        guard confirmPassword.count >= 6 else {
            errorMessage = "Password too short."
            return
        }
        guard confirmPassword == originalPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        // At this point, OTP and password confirmation are valid
        showSuccess = true
        errorMessage = ""

        // In real app: mark user verified or proceed to login screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            dismiss()
        }
    }
}
