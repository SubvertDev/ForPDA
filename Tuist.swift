import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("16.4.0"),
        swiftVersion: "6.1.2",
    )
)
