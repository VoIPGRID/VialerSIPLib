//
//  Message.swift
//  LibExample
//
//  Created by Manuel on 08/10/2019.
//  Copyright © 2019 Harold. All rights reserved.
//



enum Message {

    case feature(Feature)
    
    enum Feature {
        case userHandling(UserHandling)
        case settings(Settings)
        case calling(Calling)
        
        enum UserHandling {
            case useCase(UseCase)
            
            enum UseCase {
                case login(LogIn)
                case logout(LogOut)
                
                enum LogIn {
                    case action(Action)
                    
                    enum Action {
                        case logIn(String, String) // logIn(username, password)
                        case logInConfirmed(User)
                    }
                }
                
                enum LogOut {
                    case action(Action)
                    
                    enum Action {
                        case logOut(User)
                        case logOutConfirmed(User)
                    }
                }
            }
        }
        
        enum Settings {
            case useCase(UseCase)
            
            enum UseCase {
                case transport(Transport)
                case register(Register)
                case unregister(Unregister)
            }
            
            enum Transport {
                case action(Action)
                
                enum Action {
                    case activate(TransportOption)
                    case didActivate(TransportOption)
                }
            }
            
            enum Register{}
            enum Unregister{}
        }
        
        enum Calling {
            case useCase(UseCase)
            
            enum UseCase {
                case call(Calling)
                
                enum Calling {
                    case action(Action)
                    
                    enum Action {
                        case start
                        case callDidStart(Call)
                        case stop(Call)
                        case callDidStop(Call)
                    }
                }
            }
        }
    }
}
