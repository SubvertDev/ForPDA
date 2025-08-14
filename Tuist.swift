import ProjectDescription

let tuist = Tuist(
    project: .tuist(
        compatibleXcodeVersions: .list(["16.4.0", "26.0.0"]),
        swiftVersion: "6.1.2",
    )
)
