import ProjectDescription

let tuist = Tuist(
    fullHandle: "forpda/forpda",
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("16.2.0"),
        swiftVersion: "6.0.0"
    )
)
