//
//  FeedbackView.swift
//  Afrobeats AI
//
//  Created by Alex Paul on 6/11/24.
//

import SwiftUI

import SwiftUI

struct FeedbackView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var comment: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Your Details")) {
                    TextField("Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                    TextField("Age", text: $age)
                        .keyboardType(.numberPad)
                }

                Section(header: Text("Your Feedback")) {
                    TextEditor(text: $comment)
                        .frame(height: 200)
                }

                Button("Submit Feedback") {
                    submitFeedback()
                }
            }
            .navigationBarTitle("Feedback")
        }
    }

    private func submitFeedback() {
        // Handle the feedback submission logic
        print("Feedback submitted: \(name), \(email), \(age), \(comment)")
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
