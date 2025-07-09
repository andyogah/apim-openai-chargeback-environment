"""
This module interacts with Azure OpenAI Service via Azure API Management (APIM).

Features:
- Sends a prompt to the OpenAI model deployed via APIM and retrieves the response.
- Demonstrates the usage of the chat completion function with a sample prompt.

Note:
- Ensure the APIM endpoint, subscription key, and model deployment name are correctly configured.
- Sensitive information like subscription keys should be stored securely.
"""

# import os
# from dotenv import load_dotenv
import requests

# Load environment variables from config.env
# load_dotenv()

# Azure OpenAI setup via APIM
# APIM_ENDPOINT = os.getenv("AZURE_APIM_ENDPOINT")
# APIM_SUBSCRIPTION_KEY = os.getenv("AZURE_APIM_SUBSCRIPTION_KEY")
# OPENAI_MODEL = os.getenv("AZURE_OPENAI_MODEL_DEPLOYMENT_NAME")

# APIM_ENDPOINT = "https://apim20250402215351.azure-api.net"
# APIM_SUBSCRIPTION_KEY = "b7d6bd9d7ac14d72acebd74a19a40ec9"
# OPENAI_MODEL = "gpt-4o"


def chat_completion(prompt):
    """
    Sends a prompt to OpenAI via Azure API Management (APIM) and retrieves the response.

    Args:
        prompt (str): The input prompt to send to OpenAI.

    Returns:
        str: The response from OpenAI, or an error message if the request fails.
    """
    # headers = {
    #     "Content-Type": "application/json",
    #     "Ocp-Apim-Subscription-Key": APIM_SUBSCRIPTION_KEY
    # }

    headers = {
        "Content-Type": "application/json",
        "Ocp-Apim-Subscription-Key": "6c1a0021ee7542c2a915e0f5e5b7d7ff",
    }

    # url = f'{APIM_ENDPOINT}/openai/deployments/{OPENAI_MODEL}/chat/completions?api-version={API_VERSION}'
    #url = 'https://apim20250403085200.azure-api.net/openapi/deployments/text-embedding/embeddings?api-version=2024-02-01'
    url = "https://apim20250412193301.azure-api.net/openapi/deployments/gpt-4o/chat/completions?api-version=2024-02-01"



    #payload for completions and chat completions
    payload = {
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt},
        ],
        "max_tokens": 2048,
    }

    #payload for text embedding
    # payload = {
    #     "input": prompt}

    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)

        if response.status_code != 200:
            return f"Error: Unable to process the request. Status code: {response.status_code}"

        # comment out if checking for text-embeddings. only use for chat-completions
        response_json = response.json()
        if "choices" not in response_json:
            return "Error: Unexpected response format from OpenAI."

        return response_json["choices"][0]["message"]["content"]


        #comment out if checking for chat-completions. only use for text-embeddings
        # response_json = response.json()
        # if "data" not in response_json:
        #     return "Error: Unexpected response format from OpenAI."

        # # Extract and return the embedding
        # embedding = response_json["data"][0]["embedding"]
        # return embedding

    # Handle potential errors
    except requests.exceptions.RequestException as e:
        return f"Error: Failed to connect to OpenAI API. Details: {e}"


def main():
    """
    Demonstrates the usage of the chat completion function with a sample prompt.
    """

    # CHAT COMPLETION PROMPTS
    #prompt = "Hey buddy, how are you doing today?"
    prompt = "I am fine, thank you. Hanging in there"
    #prompt = "What is the capital of France?"
    #prompt = "Tell me about the meeting DOI AI Working Session today. I was told I am doing a demo, but don't know what to say."

    #SENTIMENT ANALYSIS PROMPTS
    #prompt = "What is the sentiment of the following text? I love spending time with my family.\n\n Sentiment:"
    #prompt = "What is the sentiment of the following text? The weather is beautiful today, and I feel great!\n\n Sentiment:"
    #prompt = "Negate the following sentence.The price for bubblegum increased on thursday.\n\n Negated Sentence:"


    #SUMMARIZATION PROMPTS
    # prompt = "Summarize the following text:\n\nArtificial intelligence (AI) has a long and storied history that dates back to ancient times. While the term 'artificial intelligence' itself was coined in the mid-20th century, the concept of creating intelligent machines has fascinated humanity for centuries. Early myths and legends often featured mechanical beings imbued with human-like qualities, such as the ancient Greek tale of Talos, a giant automaton made of bronze, and the Chinese legend of Yan Shi, an engineer who created a life-sized humanoid robot.\n\nThe modern era of AI began in the 1950s, when the field of computer science was still in its infancy. In 1956, a group of researchers convened at Dartmouth College for the Dartmouth Conference, which is widely considered the birthplace of AI as a formal academic discipline. The conference was organized by John McCarthy, Marvin Minsky, Nathaniel Rochester, and Claude Shannon, and it brought together leading thinkers to discuss the possibilities of creating machines that could simulate human intelligence.\n\nEarly AI research focused on symbolic AI, also known as 'Good Old-Fashioned AI' (GOFAI). This approach involved using symbols and rules to represent knowledge and reasoning processes. Researchers developed various algorithms and techniques, such as heuristic search, rule-based systems, and expert systems, to solve problems and perform tasks that required human-like intelligence. Notable early achievements included the development of the Logic Theorist, a program created by Allen Newell and Herbert A. Simon in 1955 that could prove mathematical theorems, and the General Problem Solver, another program by Newell and Simon that could solve a wide range of problems using a more general approach.\n\nDespite these early successes, AI research faced significant challenges and setbacks in the following decades. One major obstacle was the 'combinatorial explosion' problem, which arose from the exponential growth in the number of possible solutions to complex problems. This made it difficult for symbolic AI systems to scale and handle real-world tasks. Additionally, early AI systems often lacked the ability to learn and adapt, limiting their usefulness and flexibility.\n\nThe field of AI underwent a resurgence in the 1980s and 1990s with the advent of machine learning, a new paradigm that focused on developing algorithms that could learn from data and improve their performance over time. Machine learning shifted the emphasis from explicitly programmed rules to statistical models and data-driven approaches. One of the key breakthroughs in this era was the development of neural networks, inspired by the structure and function of the human brain. Researchers such as Geoffrey Hinton, Yann LeCun, and Yoshua Bengio made significant contributions to the field by developing deep learning techniques that allowed neural networks to learn and represent complex patterns in data.\n\nThe rise of big data and advances in computing power further accelerated the progress of AI in the 21st century. With the proliferation of digital data from various sources, such as social media, sensors, and online transactions, AI systems gained access to vast amounts of information that could be used for training and improving machine learning models. Additionally, the advent of powerful graphics processing units (GPUs) enabled the training of large-scale neural networks, making deep learning more practical and effective.\n\nAI has since made significant strides in various domains, including natural language processing, computer vision, robotics, and game playing. Notable achievements include the development of IBM's Watson, which won the game show Jeopardy! in 2011, and Google's AlphaGo, which defeated the world champion Go player Lee Sedol in 2016. These milestones demonstrated the potential of AI to tackle complex and challenging tasks that were once thought to be beyond the reach of machines.\n\nIn the realm of natural language processing, AI has made remarkable progress in understanding and generating human language. Advances in techniques such as recurrent neural networks (RNNs), long short-term memory (LSTM) networks, and transformers have enabled the development of sophisticated language models, such as OpenAI's GPT-3, which can generate coherent and contextually relevant text based on a given prompt. These models have a wide range of applications, including chatbots, language translation, content generation, and sentiment analysis.\n\nComputer vision, another key area of AI research, has also seen significant advancements. Convolutional neural networks (CNNs) have become the standard approach for image recognition and classification tasks. AI systems can now accurately identify objects, faces, and scenes in images and videos, enabling applications such as autonomous vehicles, surveillance, and medical imaging. For instance, AI-powered diagnostic tools can analyze medical images to detect diseases such as cancer, improving the accuracy and speed of diagnosis.\n\nRobotics, a field that combines AI with engineering, has benefited from advances in machine learning and computer vision. AI-powered robots are now capable of performing a wide range of tasks, from assembling products in factories to assisting with surgeries in hospitals. These robots can learn from their experiences and adapt to new situations, making them more versatile and reliable. In addition to industrial and medical applications, robots are also being used for exploration, such as NASA's Mars rovers, which use AI to navigate and conduct scientific experiments on the Martian surface.\n\nThe impact of AI on society is profound and far-reaching. In the business world, AI is being used to optimize operations, improve customer service, and drive innovation. For example, AI algorithms can analyze market trends and consumer behavior to provide insights for decision-making, while chatbots and virtual assistants can handle customer inquiries and support. In the healthcare industry, AI is being used to develop personalized treatment plans, predict disease outbreaks, and assist in drug discovery. In education, AI-powered tools are being used to provide personalized learning experiences, assess student performance, and automate administrative tasks.\n\nDespite the many benefits of AI, there are also significant challenges and ethical considerations that need to be addressed. One major concern is the potential for job displacement as AI systems become capable of performing tasks that were previously done by humans. This has led to fears of widespread unemployment and economic disruption, particularly in industries that rely heavily on manual labor and routine tasks. To mitigate these effects, it is important to invest in education and training programs that equip workers with the skills needed for the AI-driven economy.\n\nAnother concern is the ethical implications of AI, particularly in areas such as privacy, security, and decision-making. As AI systems become more autonomous, there is a growing need for frameworks and regulations to ensure that they are used responsibly and transparently. This includes addressing issues such as data privacy, algorithmic bias, and accountability. For example, biased AI algorithms can perpetuate and amplify existing social inequalities, leading to unfair outcomes in areas such as hiring, lending, and law enforcement. To address this, researchers and policymakers are working on developing techniques and standards for ensuring fairness and transparency in AI systems.\n\nIn addition to these ethical considerations, there are also technical challenges that need to be overcome. While AI systems can be very effective at specific tasks, they often struggle with generalization and adaptability. This means that an AI system that is trained to perform a particular task may not be able to handle variations of that task or perform entirely different tasks. Researchers are working on developing more flexible and robust AI systems that can better mimic the versatility and adaptability of human intelligence. This includes exploring new approaches such as transfer learning, meta-learning, and unsupervised learning.\n\nFurthermore, the development and deployment of AI systems require substantial computational resources and energy, which can be a limiting factor in their scalability. Efforts are underway to create more efficient algorithms and hardware that can reduce the energy consumption and costs associated with AI. This includes the exploration of new computing paradigms, such as quantum computing, which has the potential to revolutionize the field of AI by providing unprecedented processing power. Quantum computing leverages the principles of quantum mechanics to perform calculations that are beyond the reach of classical computers, enabling the development of more powerful and efficient AI algorithms.\n\nLooking ahead, the future of AI holds immense promise, but it also requires careful consideration of the potential risks and challenges. By addressing these issues proactively, society can harness the full potential of AI to improve lives and drive innovation while ensuring that its development and use are aligned with ethical and social values. As AI continues to evolve, it will be crucial to foster collaboration between researchers, policymakers, industry leaders, and the public to create a sustainable and inclusive AI-powered future.\n\nThe journey of AI is one of both great achievements and ongoing challenges. From its early beginnings in ancient myths to its current status as a transformative technology, AI has come a long way. As we look to the future, it is important to recognize the potential of AI to drive positive change while remaining mindful of the ethical, social, and technical considerations that come with it. By working together, we can shape the future of AI in a way that benefits all of humanity and ensures that this powerful technology is used for the greater good."

    
    #LANGUAGE TRANSLATION PROMPTS
    #prompt = "Translate the following English text to French: 'Hello, how are you?'"
    #prompt = "Translate the following English text to Spanish: 'The quick brown fox jumps over the lazy dog.'"
    
    #CREATIVE WRITING PROMPTS
    #prompt = "Write a short story about a cat who discovers a hidden world in the backyard."
    #prompt = "Generate a list of 10 unique and creative names for a new coffee shop, including a brief description of each name's theme or concept."
    #prompt = "Write a poem about the beauty of nature in springtime, using vivid imagery and sensory details."
    #prompt = "Write a short story about a time traveler who visits the year 2050 and discovers a world transformed by technology."
    #prompt = "Write a compelling and concise product description for wireless noise-canceling headphones that emphasizes their features, benefits, and unique selling points."

    #TEXT EMBEDDING PROMPTS
    #prompt = "The quick brown fox jumps over the lazy dog."
    # prompt = "Provide a sentence or document to be embedded into vector representation"
    
    #comment out when checking for chat-completions. only use for text-embeddings
    # Get the embedding from OpenAI
    # embedding = chat_completion(prompt)

    # if isinstance(embedding, list):
    #     print("Text Embedding Result:")
    #     print(embedding)
    # else:
    #     print(embedding)

    # Get the response from OpenAI
    response = chat_completion(prompt)

    print("Chat Completion Result:")
    print(response)


if __name__ == "__main__":
    main()
