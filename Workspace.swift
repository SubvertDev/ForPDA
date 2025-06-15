import ProjectDescription

let workspace = Workspace(
    name: "ForPDA",
    projects: ["**"],
    generationOptions: .options(
        lastXcodeUpgradeCheck: "16.4.0"
    )
)
