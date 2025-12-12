import ProjectDescription

let tuist = Tuist(
    fullHandle: "forpda/forpda",
    project: .tuist(
        compatibleXcodeVersions: .upToNextMajor("26.2"),
        swiftVersion: "6.2.3",
        generationOptions: .options(
            optionalAuthentication: true
        )
    )
)
