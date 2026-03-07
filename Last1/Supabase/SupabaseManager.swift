import Foundation
import Supabase

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://itnepjifwvnjghmwshii.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Iml0bmVwamlmd3ZuamdobXdzaGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3MzQ2MzksImV4cCI6MjA4NzMxMDYzOX0.Sm0MrXjyBH9uBtnceYcLBUgtVMS3MXmnFAPQwz53e_M"
    )
}
