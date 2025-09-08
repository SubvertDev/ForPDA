import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("26.0.0"),
        swiftVersion: "6.1.2",
    )
)
