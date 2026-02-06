export interface Message {
  role: "user" | "model";
  text: string;
}

export interface ChatRequest {
  messages: Message[];
}

export interface ChatResponse {
  message: Message;
}
