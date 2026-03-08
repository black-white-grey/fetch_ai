import csv
import random

titles = [
    "Deep Learning for Computer Vision: A Review",
    "Generative Adversarial Networks for Image Synthesis",
    "Attention Is All You Need: Transformers Explained",
    "Reinforcement Learning in Robotics",
    "Natural Language Processing with Large Language Models",
    "Quantum Computing: A Post-Moore Paradigm",
    "Edge Computing for IoT Devices",
    "Federated Learning: Privacy-Preserving AI",
    "Blockchain for Supply Chain Transparency",
    "Cybersecurity in the Age of AI",
    "Explainable AI (XAI) for Medical Diagnosis",
    "Graph Neural Networks for Social Network Analysis",
    "Time Series Forecasting with LSTM",
    "Self-Supervised Learning in Speech Recognition",
    "Ethics in Artificial Intelligence",
    "Optimization Algorithms for Deep Neural Networks",
    "Hardware Accelerators for Machine Learning",
    "Serverless Computing Architecture",
    "5G Networks and Low Latency Applications",
    "Microservices vs Monolithic Architectures",
    "Autonomous Driving: Perception and Planning",
    "Human-Computer Interaction in Virtual Reality",
    "Big Data Analytics for Predictive Maintenance",
    "Distributed Systems Consensus Protocols",
    "Cloud Computing Security Challenges"
]

authors = [
    "Alice Smith", "Bob Jones", "Charlie Brown", "Diana Prince", "Eve Adams",
    "Frank Castle", "Grace Hopper", "Heidi Klum", "Ivan Drago", "Judy Garland"
]

keywords_pool = [
    "Machine Learning", "Artificial Intelligence", "Deep Learning", "Neural Networks",
    "Computer Vision", "NLP", "Robotics", "IoT", "Blockchain", "Cybersecurity",
    "Data Science", "Cloud Computing", "Edge Computing", "Quantum Computing", "Algorithms"
]

# Generate 100 rows
with open('cs_research_papers.csv', 'w', newline='', encoding='utf-8') as file:
    writer = csv.writer(file)
    writer.writerow(["Title", "Author", "Year", "Abstract", "Keywords"])
    
    for i in range(100):
        title = random.choice(titles) + f" (Part {i%5 + 1})"
        author = f"{random.choice(authors)} et al."
        year = random.randint(2018, 2026)
        abstract = f"This paper explores the applications and challenges of {title.lower()} within the broader context of computer science. We propose a novel architecture that improves performance by 15% over state-of-the-art baselines."
        keywords = ", ".join(random.sample(keywords_pool, 3))
        
        writer.writerow([title, author, year, abstract, keywords])

print("Generated cs_research_papers.csv with 100 rows.")
