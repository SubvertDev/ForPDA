import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("16.2.0"),
        swiftVersion: "6.0.0"
    )
)
