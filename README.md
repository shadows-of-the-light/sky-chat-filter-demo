# Sky chat filter demo

The goal of this project is to demonstrate a better chat filter for the game Sky: Children of the Light using a decision AI model.

## Advanteges

### Accuracy

There are many ways to moderate chat messages in games, but it's hard to achieve both accuracy and context-awareness with traditional methods. This project demonstrates how a decision AI model can improve chat filtering by considering both the message and its context.

For example the message *"Read a book"* could be interpreted differently depending on the context.

An innocent answer to a friendly question:

> What do you like to do in your free time?
> Read a book

An insult during a disagreement:

> I don't think you're right. What's your source?
> Read a book

### Speed and cost

AI models can process unstructured data like chat messages, but traditional LLMs often struggle with real-time performance due to their computational complexity. Decision AI models, on the other hand, can provide faster responses while maintaining high accuracy, making them suitable for in-game chat filtering.

In this demo I used `gemini-decision-1` with a free-tier Gemini API key. The response times were less than a second, and the free-tier usage let me send 120 requests per minute.

### Limitations and applying to the real thing

Although this model was enough for this demo, Google's API is not the right choice for Sky (because of rate limits and privacy concerns). In a real-world scenario, a local model on the server side would be more appropriate.

## Running the demo on Windows

### Prerequisites

- Erlang/OTP available on `PATH`
- Rebar3 (the project includes `rebar3.cmd`)
- A Gemini API key

Set the API key in your Windows environment:

```powershell
$env:GEMINI_API_KEY="your-api-key"
```

### Compile

From the project directory:

```powershell
.\rebar3.cmd compile
```

### Run the demo

From the project directory:

```powershell
.\run_demo.cmd
```

You can also pass a custom message and optional context:

```powershell
.\run_demo.cmd "your message"
.\run_demo.cmd "your message" "optional context"
```

Examples:

```powershell
.\run_demo.cmd "hey, want to help with this quest?"
.\run_demo.cmd "you are trash" "[match chat after a loss]"
```

### Understanding the output

The output of the demo is a JSON object that indicates whether the message is considered safe or potentially harmful, along with the reasoning behind the decision and the confidence of the model in that decision.

```json
{
  "answers": {
    "decision": {
      "choice": "send",
      "confidence": 9.98542410255752410642e-01,
      "probabilities": {
        "block": 1.45758974424750370642e-03,
        "send": 9.98542410255752410642e-01
      },
      "type": "choice"
    },
    "intent": {
      "choice": "social",
      "confidence": 6.49406663745186962799e-01,
      "probabilities": {
        "harassment": 4.20473286542374577457e-03,
        "neutral": 3.43750588331318773783e-01,
        "sexual": 1.87969469788326409496e-03,
        "social": 6.49406663745186962799e-01,
        "spam": 7.58320360187112602057e-04
      },
      "type": "choice"
    },
    "vulgarity": {
      "confidence": 9.71978510873139245341e-01,
      "legend": {
        "0": "Clean or harmless.",
        "1": "Mild vulgarity or profanity.",
        "2": "Clearly offensive or sexually suggestive.",
        "3": "Severe, explicit, threatening, or hate-directed language."
      },
      "probabilities": {
        "0": 9.71978510873139245341e-01,
        "1": 2.44123106904876631396e-02,
        "2": 2.11501051860485877673e-03,
        "3": 1.49416791776808073784e-03
      },
      "score": 3.31248354810016257255e-02,
      "type": "score"
    }
  },
  "usage": {
    "input_tokens_by_modality": [
      {
        "modality": "text",
        "tokens": 399
      }
    ],
    "total_input_tokens": 399,
    "total_output_tokens": 0,
    "total_tokens": 399
  }
}
```
