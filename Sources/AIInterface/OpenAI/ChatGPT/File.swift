//
//  File.swift
//  
//
//  Created by Scott Lydon on 5/17/24.
//
/*
 https://platform.openai.com/docs/api-reference
 */

import Foundation
import Callable

public struct Secrets {
    public static let openAIKey = ""
}

public extension String {

    func url() throws -> URL {
        guard let newURL = self.url else {
            throw GenericError(text: "We could not convert this string to a url.")
        }
        return newURL
    }
}

public extension URL {

    // SwiftLint rule is disabled for the following code block to allow using `try!`.
    // This is safe here as the URL formation is controlled and validated through unit tests.
    // swiftlint: disable force_try

    /// Creates a URL for accessing the DaVinci engine API of OpenAI.
    /// - Parameter version: The API version number. Default is 1.
    /// - Returns: A `URL` object pointing to the DaVinci engine API endpoint.
    /// - Note: The `try!` is used because the URL string is well-formed and controlled, making a runtime error unlikely.
    static func davinci(version: UInt = 1) -> URL {
        try! "https://api.openai.com/v\(version)/engines/davinci/completions".url()
    }

    ///
    /// Creates a URL for accessing the GPT-3.5 Turbo chat API of OpenAI.
    /// - Parameter version: The API version number. Default is 1.
    /// - Returns: A `URL` object pointing to the GPT-3.5 Turbo chat API endpoint.
    /// - Note: As with other URL methods in this extension, the use of `try!` assumes the URL is guaranteed to be correct.
    static func gpt35Turbo(version: UInt = 1) -> URL {
        try! "https://api.openai.com/v\(version)/chat/completions".url()
    }

    /// Creates a URL for accessing the models API of OpenAI.
    /// - Parameter version: The API version number. Default is 1.
    /// - Returns: A `URL` object pointing to the models API endpoint.
    /// - Note: The `try!` is justified by the static, predictable nature of the URL string, eliminating typical risks of errors.
    static func models(version: UInt = 1) -> URL {
        try! "https://api.openai.com/v\(version)/models".url()
    }

    // Re-enable the SwiftLint rule that was previously disabled.
    // swiftlint: enable force_try
}


// URLRequest public extension to create an OpenAI API request
public extension URLRequest {

    static func gptBuilder(_ text: String) -> URLRequest {
        URLRequest.gpt35TurboChatRequest(
            messages: .buildUserMessage(
                content: .goalTreeFrom(goal: text)
            )
        )
    }

    static var models: URLRequest {
        // Set your API key here
        // file not tracked by git, saved also in keychain.
        let apiKey = Secrets.openAIKey
        var request = URLRequest(url: .models())
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        return request
    }

    static func openAIRequest(
        url: URL = .davinci(),
        prompt: String
    ) -> URLRequest {
        // Set your API key here
        // file not tracked by git, saved also in keychain.
        let apiKey = Secrets.openAIKey

        // Configure the API request

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Set the parameters for the API call
        let parameters: [String: Any] = [
            "prompt": prompt, // The text prompt to send to the API
            "max_tokens": 50,  // The maximum number of tokens (words or word pieces) to generate
            "n": 1,            // The number of generated responses to return
            "stop": ["\n"]     // The sequence(s) where the API should stop generating tokens
        ]

        // Encode the parameters as JSON
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

        return request
    }

    /**
         Creates a URLRequest for the GPT-3.5 Turbo chat model.

         - Parameters:
           - messages: An array of dictionaries with a `role` and `content` key.
                       Each dictionary represents a message in the conversation.
                       The `role` can be either "user" or "assistant", and `content`
                       contains the text of the message.
           - temperature: A double value that adjusts the randomness of the generated
                          response. Higher values (e.g., 1.0) make the output more random,
                          while lower values (e.g., 0.1) make it more deterministic.
                          The default value is 0.7.
           - url: The API endpoint URL. The default value is the GPT-3.5 Turbo URL.

         - Returns: A URLRequest configured for the GPT-3.5 Turbo chat model.
         */
        static func gpt35TurboChatRequest(
            messages: [[String: String]],
            temperature: Double = 0.7,
            url: URL = .gpt35Turbo()
        ) -> URLRequest {
            // Set your API key here
            // file not tracked by git, saved also in keychain.
            let apiKey = Secrets.openAIKey

            // Configure the API request
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            // Set the parameters for the API call
            let parameters: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": messages,
                "temperature": temperature
            ]

            // Encode the parameters as JSON
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)

            return request
        }
}

// Extension to create messages for GPT-3.5 Turbo chat requests
public extension Array where Element == [String: String] {
    static func buildUserMessage(content: String) -> [[String: String]] {
        let message = ["role": "user", "content": content]
        return [message]
    }

    static func buildAssistantMessage(content: String) -> [[String: String]] {
        let message = ["role": "assistant", "content": content]
        return [message]
    }
}

public extension GoodPrompt {
    struct Example {
        /// "Few-shot" prompting techniques improve the output by helping the ai by giving examples.
        public let exampleInput: String
        public let exampleOutput: String
    }
}

public protocol HasPrompt {
    /// Defines a string that represents the formatted prompt for AI processing.
    var prompt: String { get }
}

public struct ChainOfThoughtPrompt: HasPrompt {
    /// A brief description that introduces the reasoning scenario.
    let description: String
    /// A list of logical steps the AI should consider to solve the problem or answer the question.
    let thoughtProcess: [String]

    /// Combines description and thought process into a single prompt string.
    /// This helps in guiding the AI's reasoning in a public structured manner.
    public var prompt: String {
        description + "\n" + thoughtProcess.joined(separator: "\n")
    }
}

public struct PromptChain: HasPrompt {
    /// The initial prompt that starts the thought process.
    public let initialPrompt: String
    /// A sequence of follow-up prompts that delve deeper into the topic or refine the response.
    public let subsequentPrompts: [String]

    /// Combines all prompts into a coherent chain.
    /// This chaining is crucial for detailed exploration or complex problem-solving.
    public var prompt: String {
        (initialPrompt + subsequentPrompts.joined(separator: "\n"))
    }
}

public struct GraphBasedPrompt: HasPrompt {
    /// A description of the graph or visual data being considered.
    public let graphDescription: String
    /// Detailed reasoning that interprets the graph to form conclusions or insights.
    public let reasoningFromGraph: String

    /// Merges graphical description and reasoning into a prompt.
    /// This integration helps the AI to understand and process visual data in context.
    public var prompt: String {
        graphDescription + "\n" + reasoningFromGraph
    }
}

public struct GoodPrompt: HasPrompt {
    /// Direct inpublic structions for zero-shot prompting, usually just a single clear question or command.
    public let instructions: String
    /// List of examples that help illustrate the expected format or content of responses.
    public let examples: [Example]
    /// A field for specifying undesirable elements in the AI's responses,
    ///  ensuring certain types of content are excluded.
    public let whatIDontWant: String?

    /// Optional properties for advanced prompting techniques.
    public let chainOfThought: ChainOfThoughtPrompt?
    public let promptChain: PromptChain?
    public let graphPrompt: GraphBasedPrompt?

    /// Computes the final combined prompt from all available components.
    /// This final prompt is used to guide the AI in generating a comprehensive and relevant response.
    public var prompt: String {
        [
            instructions,
            examples.map(\.prompt).joined(separator: "\n"),
            chainOfThought?.prompt,
            promptChain?.prompt,
            graphPrompt?.prompt
        ].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: "\n")
    }
}

extension GoodPrompt.Example: HasPrompt {
    /// Formats an input-output pair as a prompt to aid few-shot learning by the AI.
    /// This helps the AI understand the context and expected response public structure better.
    public var prompt: String {
        "Example Input: \(exampleInput)\nExample Output: \(exampleOutput)"
    }
}

public extension String {

    // swiftlint: disable function_body_length
    // swiftlint: disable line_length
    static func goalTreeFrom(goal: String) -> String {
        """
        Example prompt:
        Return all the necessary sub tasks for the following goal: “become a lawyer in Ireland.” For each of this sub tasks return a list of sub tasks.  Keep on going, until a task tree is created, where each leaf is an easy task.  Return the task tree exclusively as a logically public structured json object.  Omit anything else.

        Make sure it will be convertible to the following public structs (if it will take less than a day, set daysEstimate to 1):

        // MARK: - Choices
        public struct Choices: Codable {
            public let thisSteps: [ThisStep]
        }

        // MARK: - ThisStep
        public struct ThisStep: Codable {
            public let title: String
            public let daysEstimate: Int
            public let steps: [Step]
        }

        // MARK: - Step
        public struct Step: Codable {
            public let subtitle: String
            public let subdaysEstimate: Int
        }

        Example response:
        {
          "thisSteps": [
            {
              "title": "Research law schools in Ireland",
              "daysEstimate": 3,
              "steps": [
                {
                  "subtitle": "Look up law schools in Ireland online",
                  "subdaysEstimate": 1
                },
                {
                  "subtitle": "Research admission requirements for each school",
                  "subdaysEstimate": 2
                },
                {
                  "subtitle": "Make a list of top law schools in Ireland",
                  "subdaysEstimate": 1
                }
              ]
            },
            {
              "title": "Study for LSAT",
              "daysEstimate": 30,
              "steps": [
                {
                  "subtitle": "Purchase LSAT study materials",
                  "subdaysEstimate": 2
                },
                {
                  "subtitle": "Create study plan for LSAT",
                  "subdaysEstimate": 3
                },
                {
                  "subtitle": "Study for LSAT",
                  "subdaysEstimate": 25
                }
              ]
            },
            {
              "title": "Apply to law schools in Ireland",
              "daysEstimate": 120,
              "steps": [
                {
                  "subtitle": "Gather necessary application materials",
                  "subdaysEstimate": 5
                },
                {
                  "subtitle": "Fill out and submit applications",
                  "subdaysEstimate": 115
                }
              ]
            },
            {
              "title": "Prepare for move to Ireland",
              "daysEstimate": 27,
              "steps": [
                {
                  "subtitle": "Research living arrangements in Ireland",
                  "subdaysEstimate": 2
                },
                {
                  "subtitle": "Apply for necessary visas",
                  "subdaysEstimate": 15
                },
                {
                  "subtitle": "Pack and prepare for move",
                  "subdaysEstimate": 10
                }
              ]
            }
          ]
        }

        Current prompt:
        Return all the necessary sub tasks for the following goal: “\(goal)” For each of the sub tasks return a list of sub tasks.  Keep on going, until a task tree is created, where each leaf is an easy task.  Return the task tree exclusively as a logically public structured json object.  Omit anything else, JSON ONLY!.

        Make sure it will be convertible to the following public structs (if it will take less than a day, set daysEstimate to 1):

        // MARK: - Choices
        public struct Choices: Codable {
            public let thisSteps: [ThisStep]
        }

        // MARK: - ThisStep
        public struct ThisStep: Codable {
            public let title: String
            public let daysEstimate: Int
            public let steps: [Step]
        }

        // MARK: - Step
        public struct Step: Codable {
            public let subtitle: String
            public let subdaysEstimate: Int
        }
        """
    }
    // swiftlint: enable function_body_length
    // swiftlint: enable line_length
}
