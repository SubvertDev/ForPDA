import ProjectDescription

let tuist = Tuist(
    fullHandle: "forpda/forpda",
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("26.0.0"),
        swiftVersion: "6.2",
    )
)
