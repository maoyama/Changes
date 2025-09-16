//
//  SectionHeader.swift
//  GitClient
//
//  Created by Makoto Aoyama on 2024/09/08.
//

import SwiftUI

struct SectionHeader: View {
    var title: String
    var callout: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .textSelection(.disabled)
            Spacer()
            Text(callout)
                .font(.callout)
                .foregroundStyle(.tertiary)
        }
    }
}
