//
//  SideMenu.swift
//  Afrobeats AI
//
//  Created by Alex Paul on 6/9/24.
//

import SwiftUI

struct SideMenu: View {
    @Binding var isShowing: Bool
    var selectedLines: Set<Int>
    var lyrics: String
    @ObservedObject var viewModel: LyricsViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            Spacer()
                                .frame(height: 70)
                                .padding()
                            ForEach(selectedLines.sorted(), id: \.self) { index in
                                let lines = lyrics.split(separator: "\n")
                                Text(String(lines[index]))
                                    .font(.body)
                                    .padding(.horizontal, 20)
                                    .foregroundColor(.black)
                            }
                            
                            Divider()
                            
                            if !viewModel.errorMessage.isEmpty {
                                Text(viewModel.errorMessage)
                                    .font(.body)
                                    .foregroundColor(.red)
                                    .padding(.horizontal, 20)
                            } else if !viewModel.translation.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Translation")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                    Text(viewModel.translation)
                                        .font(.body)
                                        .foregroundColor(.black)
                                        .padding(.horizontal, 20)
                                }
                            } else if viewModel.isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                    Spacer()
                                }
                                .padding(.vertical, 20)
                            }
                            
                            Spacer()
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
                .offset(x: isShowing ? 0 : geometry.size.width)
                .animation(.spring(), value: isShowing)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct SideMenu_Previews: PreviewProvider {
    static var previews: some View {
        SideMenu(isShowing: .constant(true), selectedLines: Set(arrayLiteral: 0, 1), lyrics: "Line 1\nLine 2\nLine 3", viewModel: LyricsViewModel())
            .preferredColorScheme(.dark)
        
        SideMenu(isShowing: .constant(true), selectedLines: Set(arrayLiteral: 0, 1), lyrics: "Line 1\nLine 2\nLine 3", viewModel: LyricsViewModel())
            .preferredColorScheme(.light)
    }
}
